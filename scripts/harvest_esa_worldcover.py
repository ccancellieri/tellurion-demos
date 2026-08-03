"""Validate and derive the bounded ESA WorldCover STAC harvest contract."""

from dataclasses import dataclass
import re
from urllib.parse import urlsplit


COLLECTION_ID = "esa-worldcover"
ITEM_ID = "ESA_WorldCover_10m_2021_v200_N39E012"
EXPECTED_VALUES = [10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 100]
EXPECTED_CLASS_METADATA = {
    10: ("006400", "Tree cover"),
    20: ("FFBB22", "Shrubland"),
    30: ("FFFF4C", "Grassland"),
    40: ("F096FF", "Cropland"),
    50: ("FA0000", "Built-up"),
    60: ("B4B4B4", "Bare / sparse vegetation"),
    70: ("F0F0F0", "Snow and ice"),
    80: ("0064C8", "Permanent water bodies"),
    90: ("0096A0", "Herbaceous wetland"),
    95: ("00CF75", "Mangroves"),
    100: ("FAE6A0", "Moss and lichen"),
}


@dataclass(frozen=True)
class Derived:
    collection: dict
    item: dict
    footprint: dict
    legend: list[dict]
    colormap: dict
    manifest_facts: dict


class HarvestError(ValueError):
    pass


def validate_and_derive(collection: dict, search: dict) -> Derived:
    if collection.get("id") != COLLECTION_ID:
        raise HarvestError("unexpected Collection")
    if collection.get("license") != "CC-BY-4.0":
        raise HarvestError("expected CC-BY-4.0 license")
    providers = collection.get("providers") or []
    names = {provider.get("name") for provider in providers}
    if "ESA" not in names or "Microsoft" not in names:
        raise HarvestError("expected ESA producer and Microsoft host")

    features = search.get("features") or []
    if len(features) != 1 or features[0].get("id") != ITEM_ID:
        raise HarvestError("unexpected Item")
    item = features[0]
    asset = (item.get("assets") or {}).get("map")
    if not isinstance(asset, dict):
        raise HarvestError("missing map asset")
    media_type = asset.get("type", "")
    if "profile=cloud-optimized" not in media_type:
        raise HarvestError("map asset is not a Cloud Optimized GeoTIFF")
    href = asset.get("href", "")
    parsed = urlsplit(href)
    if parsed.scheme != "https" or parsed.query:
        raise HarvestError("map asset must be an unsigned public HTTPS URL")

    classes = asset.get("classification:classes") or []
    values = [entry.get("value") for entry in classes]
    if values != EXPECTED_VALUES:
        if len(values) != len(set(values)):
            raise HarvestError("duplicate class value")
        raise HarvestError("unexpected classification values")
    legend = []
    for entry in classes:
        color = entry.get("color-hint", "")
        label = entry.get("description", "")
        if not re.fullmatch(r"[0-9A-Fa-f]{6}", color):
            raise HarvestError("invalid color-hint")
        expected_color, expected_label = EXPECTED_CLASS_METADATA[entry["value"]]
        if color != expected_color:
            raise HarvestError("unexpected color-hint")
        if not label:
            raise HarvestError("classification description is required")
        if label != expected_label:
            raise HarvestError("unexpected classification description")
        legend.append(
            {"value": entry["value"], "label": label, "color": f"#{color.upper()}"}
        )

    properties = item.get("properties") or {}
    footprint = {
        "type": "FeatureCollection",
        "features": [
            {
                "type": "Feature",
                "id": 1,
                "geometry": item.get("geometry"),
                "properties": {
                    "id": 1,
                    "source_item_id": ITEM_ID,
                    "start_datetime": properties.get("start_datetime"),
                    "end_datetime": properties.get("end_datetime"),
                    "product_version": properties.get("esa_worldcover:product_version"),
                    "grid_code": properties.get("grid:code"),
                },
            }
        ],
    }
    stops = [{"value": 0.0, "rgba": [0, 0, 0, 0]}]
    for entry in legend:
        color = entry["color"]
        stops.append(
            {
                "value": float(entry["value"]),
                "rgba": [
                    int(color[1:3], 16),
                    int(color[3:5], 16),
                    int(color[5:7], 16),
                    255,
                ],
            }
        )
    return Derived(
        collection=collection,
        item=item,
        footprint=footprint,
        legend=legend,
        colormap={"kind": "stops", "stops": stops},
        manifest_facts={
            "collection_id": COLLECTION_ID,
            "item_id": ITEM_ID,
            "asset_href": href,
        },
    )
