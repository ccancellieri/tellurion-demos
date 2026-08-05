"""Harvest and verify the bounded 2021 ESA WorldCover Italy source set."""

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import math
from pathlib import Path
import tempfile
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen

try:
    from scripts.harvest_esa_worldcover import HarvestError, derive_legend
except ModuleNotFoundError:  # Direct execution puts scripts/, not the project root, on sys.path.
    from harvest_esa_worldcover import HarvestError, derive_legend


COLLECTION_ID = "esa-worldcover"
PRODUCT_TOKEN = "_2021_v200_"
MAX_ITEMS = 32
SEARCH_URL = "https://planetarycomputer.microsoft.com/api/stac/v1/search"
COLLECTION_URL = "https://planetarycomputer.microsoft.com/api/stac/v1/collections/esa-worldcover"
SIGN_URL = "https://planetarycomputer.microsoft.com/api/sas/v1/sign"
ESA_S3_PREFIX = "https://esa-worldcover.s3.eu-central-1.amazonaws.com/v200/2021/map/"
SOURCE_ASSET_HOST = "ai4edataeuwest.blob.core.windows.net"
TRANSFORM_VERSION = "1"
BOUNDARY_FIXTURE = Path(__file__).resolve().parents[1] / "tests/fixtures/stac/italy-boundary.geojson"


@dataclass(frozen=True)
class ItalyDerived:
    collection: dict
    items: list[dict]
    footprints: dict
    legend: list[dict]
    manifest: dict
    mosaic: dict


def _json_bytes(value: object) -> bytes:
    return (json.dumps(value, indent=2, sort_keys=True) + "\n").encode("utf-8")


def _write_atomic(path: Path, contents: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as temporary:
        temporary.write(contents)
        temporary_path = Path(temporary.name)
    temporary_path.replace(path)


def _has_query_href(value: object) -> bool:
    return (
        isinstance(value, dict)
        and isinstance(value.get("href"), str)
        and bool(urlsplit(value["href"]).query)
    )


def _without_query_urls(value: object) -> object:
    if isinstance(value, dict):
        return {
            key: _without_query_urls(child)
            for key, child in value.items()
            if not _has_query_href(child)
        }
    if isinstance(value, list):
        return [_without_query_urls(child) for child in value if not _has_query_href(child)]
    return value


def _source_href(asset: dict) -> str:
    href = asset.get("href")
    if not isinstance(href, str):
        raise HarvestError("map asset href is required")
    parsed = urlsplit(href)
    if parsed.scheme != "https" or parsed.query or parsed.fragment:
        raise HarvestError("map asset href must not contain a query or fragment")
    if parsed.hostname != SOURCE_ASSET_HOST:
        raise HarvestError("map asset must use the trusted Planetary Computer source host")
    return href


def _official_esa_href(source_href: str) -> str:
    filename = urlsplit(source_href).path.rsplit("/", 1)[-1]
    if not filename.endswith("_Map.tif") or PRODUCT_TOKEN not in filename:
        raise HarvestError("map asset filename is not a 2021 v200 WorldCover map")
    return ESA_S3_PREFIX + filename


def _valid_bbox(bbox: object) -> list[float]:
    if not isinstance(bbox, list) or len(bbox) != 4:
        raise HarvestError("invalid bbox")
    if not all(isinstance(value, (int, float)) and math.isfinite(value) for value in bbox):
        raise HarvestError("invalid bbox")
    west, south, east, north = bbox
    if not (-180 <= west < east <= 180 and -90 <= south < north <= 90):
        raise HarvestError("invalid bbox")
    return [float(value) for value in bbox]


def _geometry_bbox(geometry: object) -> list[float]:
    if not isinstance(geometry, dict) or geometry.get("type") not in {"Polygon", "MultiPolygon"}:
        raise HarvestError("Italy boundary must contain a Polygon or MultiPolygon")

    coordinates = geometry.get("coordinates")
    values: list[tuple[float, float]] = []

    def visit(value: object) -> None:
        if isinstance(value, list) and len(value) >= 2 and all(isinstance(part, (int, float)) for part in value[:2]):
            values.append((float(value[0]), float(value[1])))
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(coordinates)
    if not values:
        raise HarvestError("Italy boundary has no coordinates")
    west, south = min(value[0] for value in values), min(value[1] for value in values)
    east, north = max(value[0] for value in values), max(value[1] for value in values)
    return _valid_bbox([west, south, east, north])


def _intersects(left: list[float], right: list[float]) -> bool:
    return left[0] <= right[2] and left[2] >= right[0] and left[1] <= right[3] and left[3] >= right[1]


def _validate_collection(collection: dict) -> None:
    if collection.get("id") != COLLECTION_ID:
        raise HarvestError("unexpected Collection")
    if collection.get("license") != "CC-BY-4.0":
        raise HarvestError("expected CC-BY-4.0 license")
    names = {provider.get("name") for provider in collection.get("providers") or []}
    if not {"ESA", "ESA WorldCover Consortium", "Microsoft"}.issubset(names):
        raise HarvestError("expected ESA, ESA WorldCover Consortium, and Microsoft providers")


def _validate_boundary(boundary: dict) -> tuple[dict, list[float]]:
    if boundary.get("type") != "Feature" or boundary.get("properties", {}).get("CNTR_ID") != "IT":
        raise HarvestError("expected pinned GISCO Italy boundary")
    properties = boundary["properties"]
    if not all(properties.get(key) for key in ("gisco:source_url", "gisco:source_sha256", "gisco:terms")):
        raise HarvestError("Italy boundary provenance is incomplete")
    geometry = boundary.get("geometry")
    return geometry, _geometry_bbox(geometry)


def validate_and_derive(collection: dict, search: dict, italy_boundary: dict) -> ItalyDerived:
    _validate_collection(collection)
    _, boundary_bbox = _validate_boundary(italy_boundary)
    features = search.get("features")
    if not isinstance(features, list) or not features:
        raise HarvestError("search returned no Items")
    if len(features) > MAX_ITEMS:
        raise HarvestError("search returned more than 32 Items")

    items = sorted(features, key=lambda item: item.get("id", ""))
    ids: set[str] = set()
    source_hrefs: set[str] = set()
    footprints = []
    legend: list[dict] | None = None
    sources = []
    item_digests = {}

    for index, item in enumerate(items, start=1):
        item_id = item.get("id")
        if not isinstance(item_id, str) or PRODUCT_TOKEN not in item_id:
            raise HarvestError("Item id must identify a 2021 v200 product")
        if item_id in ids:
            raise HarvestError("duplicate id")
        ids.add(item_id)
        asset = (item.get("assets") or {}).get("map")
        if not isinstance(asset, dict):
            raise HarvestError("missing map asset")
        if "profile=cloud-optimized" not in asset.get("type", ""):
            raise HarvestError("map asset is not a Cloud Optimized GeoTIFF")
        source_href = _source_href(asset)
        if source_href in source_hrefs:
            raise HarvestError("duplicate map href")
        source_hrefs.add(source_href)
        bbox = _valid_bbox(item.get("bbox"))
        if not _intersects(bbox, boundary_bbox):
            raise HarvestError("Item bbox does not intersect the Italy boundary query")
        item_legend = derive_legend(asset)
        if legend is None:
            legend = item_legend
        elif item_legend != legend:
            raise HarvestError("classification palette differs between Items")
        properties = item.get("properties") or {}
        official_esa_href = _official_esa_href(source_href)
        footprints.append(
            {
                "type": "Feature",
                "id": index,
                "geometry": item.get("geometry"),
                "properties": {
                    "id": index,
                    "source_item_id": item_id,
                    "start_datetime": properties.get("start_datetime"),
                    "end_datetime": properties.get("end_datetime"),
                    "product_version": properties.get("esa_worldcover:product_version"),
                    "grid_code": properties.get("grid:code"),
                },
            }
        )
        sources.append({"id": item_id, "href": official_esa_href, "bbox": bbox})
        item_digests[item_id] = hashlib.sha256(_json_bytes(item)).hexdigest()

    footprints_document = {"type": "FeatureCollection", "features": footprints}
    mosaic = {"id": "esa_worldcover_2021_italy", "sources": sources}
    manifest = {
        "boundary": {
            "digest": hashlib.sha256(_json_bytes(italy_boundary)).hexdigest(),
            "source_sha256": italy_boundary["properties"]["gisco:source_sha256"],
            "source_url": italy_boundary["properties"]["gisco:source_url"],
            "terms": italy_boundary["properties"]["gisco:terms"],
        },
        "boundary_document": italy_boundary,
        "digests": {
            "collection": hashlib.sha256(_json_bytes(collection)).hexdigest(),
            "items": item_digests,
        },
        "source": {
            "collection_id": COLLECTION_ID,
            "license": collection["license"],
            "providers": collection["providers"],
        },
        "transform_version": TRANSFORM_VERSION,
    }
    return ItalyDerived(collection, items, footprints_document, legend or [], manifest, mosaic)


def fetch_json(url: str) -> dict:
    with urlopen(url, timeout=30) as response:
        return json.load(response)


def post_json(url: str, body: dict) -> dict:
    request = Request(url, _json_bytes(body), {"Content-Type": "application/json"}, method="POST")
    with urlopen(request, timeout=30) as response:
        return json.load(response)


def fetch_live_sources(italy_boundary: dict) -> dict:
    geometry, _ = _validate_boundary(italy_boundary)
    search = post_json(
        SEARCH_URL,
        {
            "collections": [COLLECTION_ID],
            "intersects": geometry,
            "datetime": "2021-01-01T00:00:00Z/2021-12-31T23:59:59Z",
            "limit": 100,
        },
    )
    if search.get("numberMatched") is not None and search["numberMatched"] > MAX_ITEMS:
        raise HarvestError("pagination refused: more than 32 source Items match")
    if any(link.get("rel") == "next" for link in search.get("links") or []):
        raise HarvestError("pagination refused: source search supplied a next link")
    return search


def sign_asset(source_href: str) -> str:
    signed = fetch_json(f"{SIGN_URL}?{urlencode({'href': source_href})}")
    href = signed.get("href")
    if not isinstance(href, str) or not urlsplit(href).query:
        raise HarvestError("Planetary Computer signing endpoint returned no signed href")
    return href


def _stream_digest(url: str) -> tuple[int, str]:
    digest = hashlib.sha256()
    length = 0
    with urlopen(url, timeout=30) as response:
        while chunk := response.read(1024 * 1024):
            length += len(chunk)
            digest.update(chunk)
    return length, digest.hexdigest()


def verify_assets(items: list[dict]) -> dict:
    verified = {}
    for item in items:
        source_href = _source_href(item["assets"]["map"])
        signed_href = sign_asset(source_href)
        official_esa_href = _official_esa_href(source_href)
        source_length, source_digest = _stream_digest(signed_href)
        mirror_length, mirror_digest = _stream_digest(official_esa_href)
        if (source_length, source_digest) != (mirror_length, mirror_digest):
            raise HarvestError(f"official ESA mirror is not byte-identical for {item['id']}")
        verified[item["id"]] = {
            "source_href": source_href,
            "official_esa_href": official_esa_href,
            "byte_length": source_length,
            "sha256": source_digest,
        }
    return verified


def _verified_sources(derived: ItalyDerived, verified: dict | None, fixture_mode: bool) -> list[dict]:
    if verified is None:
        if not fixture_mode:
            raise HarvestError("a production release requires verified asset digests")
        return derived.mosaic["sources"]
    sources = []
    for item, source in zip(derived.items, derived.mosaic["sources"]):
        record = verified.get(item["id"])
        if not isinstance(record, dict):
            raise HarvestError(f"verified record missing for {item['id']}")
        if record.get("source_href") != item["assets"]["map"]["href"] or record.get("official_esa_href") != source["href"]:
            raise HarvestError(f"verified record does not match {item['id']}")
        if not isinstance(record.get("byte_length"), int) or record["byte_length"] <= 0:
            raise HarvestError(f"verified byte length is invalid for {item['id']}")
        if not isinstance(record.get("sha256"), str) or len(record["sha256"]) != 64:
            raise HarvestError(f"verified digest is invalid for {item['id']}")
        sources.append({**source, "byte_length": record["byte_length"], "sha256": record["sha256"]})
    return sources


def write_artifacts(
    derived: ItalyDerived,
    output: Path,
    retrieved_at: str,
    verified: dict | None = None,
    fixture_mode: bool = False,
) -> None:
    mosaic = {**derived.mosaic, "sources": _verified_sources(derived, verified, fixture_mode)}
    mosaic_bytes = _json_bytes(mosaic)
    manifest = {
        **{key: value for key, value in derived.manifest.items() if key != "boundary_document"},
        "digests": {**derived.manifest["digests"], "mosaic": hashlib.sha256(mosaic_bytes).hexdigest()},
        "retrieved_at": retrieved_at,
        "verified_assets": verified or {},
    }
    artifacts = {
        "collection.json": _json_bytes(derived.collection),
        "boundary.geojson": _json_bytes(derived.manifest["boundary_document"]),
        "footprints.geojson": _json_bytes(derived.footprints),
        "legend.json": _json_bytes(derived.legend),
        "manifest.json": _json_bytes(manifest),
        "mosaic.json": mosaic_bytes,
    }
    artifacts.update(
        {
            f"items/{item['id']}.json": _json_bytes(_without_query_urls(item))
            for item in derived.items
        }
    )
    for name, contents in artifacts.items():
        _write_atomic(output / name, contents)


def _read_fixture(fixture_dir: Path) -> tuple[dict, dict, dict]:
    return (
        json.loads((fixture_dir / "collection.json").read_text(encoding="utf-8")),
        json.loads((fixture_dir / "item-search-italy.json").read_text(encoding="utf-8")),
        json.loads((fixture_dir / "italy-boundary.geojson").read_text(encoding="utf-8")),
    )


def _read_verified_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8")).get("verified_assets") or {}


def _retrieved_at_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--fixture-dir", type=Path)
    parser.add_argument("--retrieved-at")
    parser.add_argument("--verify-assets", action="store_true")
    parser.add_argument("--reuse-verified-manifest", type=Path)
    arguments = parser.parse_args()

    if arguments.fixture_dir:
        collection, search, boundary = _read_fixture(arguments.fixture_dir)
        verified = None
    else:
        collection = fetch_json(COLLECTION_URL)
        boundary = json.loads(BOUNDARY_FIXTURE.read_text(encoding="utf-8"))
        search = fetch_live_sources(boundary)
        verified = verify_assets(validate_and_derive(collection, search, boundary).items) if arguments.verify_assets else None
        if verified is None and arguments.reuse_verified_manifest:
            verified = _read_verified_manifest(arguments.reuse_verified_manifest)
    derived = validate_and_derive(collection, search, boundary)
    write_artifacts(
        derived,
        arguments.output,
        arguments.retrieved_at or _retrieved_at_now(),
        verified,
        fixture_mode=bool(arguments.fixture_dir),
    )


if __name__ == "__main__":
    main()
