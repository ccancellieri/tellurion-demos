#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

require_file() {
  if [ ! -f "$1" ]; then
    printf 'missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

require_text() {
  if ! grep -Fq "$2" "$1"; then
    printf 'missing required text in %s: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

require_file deploy/render/roads-style.json
require_file demos/query/index.html
require_file demos/stac/index.html
require_file demos/maps/index.html

require_text deploy/render/roads-style.json '"version": 8'
require_text deploy/render/roads-style.json '"source-layer": "sample_roads"'
require_text Dockerfile 'COPY deploy/render/roads-style.json /app/styles/roads.json'
require_text deploy/render/vector.yaml 'id: roads-night'
require_text deploy/render/vector.yaml 'path: /app/styles/roads.json'
require_text render.yaml 'deploy/render/roads-style.json'

require_text demos/query/index.html 'filter-lang=cql2-text'
require_text demos/query/index.html 'highway = '\''residential'\'''
require_text demos/query/index.html 'application/geo+json'
require_file demos/stac/legend.json
require_file demos/stac/manifest.json
require_file demos/stac/footprints.geojson
cmp -s demos/stac/manifest.json data/stac/esa-worldcover-italy/manifest.json
cmp -s demos/stac/legend.json data/stac/esa-worldcover-italy/legend.json
cmp -s demos/stac/footprints.geojson data/stac/esa-worldcover-italy/footprints.geojson
require_text demos/stac/index.html 'https://tellurion-stac-harvest-demo.onrender.com'
require_text demos/stac/index.html 'source_item_id'
require_text demos/stac/index.html 'Promise.all([fetch("legend.json"), fetch("manifest.json")])'
require_text demos/stac/index.html 'Planetary Computer STAC snapshot'
require_text demos/stac/index.html 'Official ESA COG mirror'
require_text demos/stac/index.html 'Tellurion COG driver'
require_text demos/stac/index.html 'raster TileSet / PNG tiles'
require_text demos/stac/index.html 'browser map'
require_text demos/stac/index.html 'Source asset'
require_text demos/stac/index.html 'Derived by Tellurion'
require_text demos/stac/index.html 'ESA'
require_text demos/stac/index.html 'Microsoft'
require_text demos/stac/index.html 'CC BY 4.0'
require_text demos/stac/index.html 'esa_worldcover_2021_italy'
require_text demos/stac/index.html 'const italyBounds = [[6.4, 35.3], [18.7, 47.2]];'
require_text demos/stac/index.html 'map.fitBounds(italyBounds'
require_text demos/stac/index.html 'id="place-italy"'
require_text demos/stac/index.html 'id="place-milan"'
require_text demos/stac/index.html 'id="place-venice"'
require_text demos/stac/index.html 'id="place-rome"'
require_text demos/stac/index.html 'id="place-naples"'
require_text demos/stac/index.html 'id="place-palermo"'
require_text demos/stac/index.html 'data-lon="9.19" data-lat="45.464" data-zoom="12.6"'
require_text demos/stac/index.html 'data-lon="12.3358" data-lat="45.438" data-zoom="12.6"'
require_text demos/stac/index.html 'data-lon="12.4964" data-lat="41.9028" data-zoom="12.6"'
require_text demos/stac/index.html 'data-lon="14.2681" data-lat="40.8518" data-zoom="12.6"'
require_text demos/stac/index.html 'data-lon="13.3615" data-lat="38.1157" data-zoom="12.6"'
require_text demos/stac/index.html 'aria-pressed'
require_text demos/stac/index.html 'id="scale-rail"'
require_text demos/stac/index.html 'zoom < 6.5'
require_text demos/stac/index.html 'zoom < 9.5'
require_text demos/stac/index.html 'zoom < 12.5'
require_text demos/stac/index.html '≈ '
require_text demos/stac/index.html 'metresPerPixel >= 1000'
require_text demos/stac/index.html 'source-footprints'
require_text demos/stac/index.html 'maxzoom: 9'
require_text demos/stac/index.html 'maxZoom: 14'
require_text demos/stac/index.html 'bounds: italyBounds'
require_text demos/stac/index.html 'fitBoundsOptions: {padding: fitPadding(), duration: movementDuration()}'
if grep -Fq '"source-footprints": {type: "geojson", data: "footprints.geojson", maxzoom:' demos/stac/index.html; then
  printf 'source-footprints must not set an unsupported GeoJSON source maxzoom\n' >&2
  exit 1
fi
require_text demos/stac/index.html '/public/stac/catalogs/default/collections/esa_worldcover_2021_italy'
require_text demos/stac/index.html '/public/stac/catalogs/default/collections/esa_worldcover_2021_italy/items/1'
require_text demos/stac/index.html '/public/features/catalogs/default/collections/esa_worldcover_2021_italy/items?limit=1'
require_text demos/stac/index.html '/public/tiles/catalogs/default/collections/esa_worldcover_2021_italy/tiles/WebMercatorQuad'
require_text demos/stac/index.html '/{z}/{y}/{x}.png'
require_text demos/stac/index.html '/5/11/17.png'
require_text demos/stac/index.html 'type: "raster"'
require_text demos/stac/index.html 'textContent'
require_text demos/stac/index.html 'resource-collection'
require_text demos/stac/index.html 'resource-item'
require_text demos/stac/index.html 'resource-features'
require_text demos/stac/index.html 'resource-tileset'
require_text demos/stac/index.html 'resource-png'
require_text demos/stac/index.html '© EuroGeographics for the administrative boundaries'
require_text demos/stac/index.html 'Non-commercial use'
require_text demos/stac/index.html 'Dynamic PNG tile composition, not a raster OGC API Maps conformance claim.'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '/public/stac/catalogs/default/collections/esa_worldcover_2021_rome'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '/public/stac/catalogs/default/collections/esa_worldcover_2021_rome/items/1'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '/public/features/catalogs/default/collections/esa_worldcover_2021_rome/items?limit=1'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '/public/tiles/catalogs/default/collections/esa_worldcover_2021_rome/tiles/WebMercatorQuad'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '/13/3043/4380.png'
require_text demos/maps/index.html '/public/tiles/catalogs/default/collections/sample_roads/map?'
require_text demos/maps/index.html '/public/styles/catalogs/default/styles/roads-night'
require_text demos/maps/index.html 'OGC API — Styles is a draft'
require_text demos/query/index.html 'const statusBox = document.getElementById("status");'
require_text demos/stac/index.html 'const mapStatus = document.getElementById("map-status");'
require_text demos/maps/index.html 'const statusBox = document.getElementById("status");'

for page in query stac maps; do
  require_text index.html "demos/$page/"
  require_text README.md "demos/$page/"
done

require_text .github/workflows/daily.yml 'sh tests/render_protocol_gallery_contract.sh'
require_text .github/workflows/daily.yml 'for page in vector raster zarr 3d query stac maps'
require_text .github/workflows/daily.yml 'demo: CQL2 feature filter'
require_text .github/workflows/daily.yml 'filter-lang=cql2-text'
require_text .github/workflows/daily.yml 'demo: STAC feature projection'
require_text .github/workflows/daily.yml '/13/3043/4380.png'
require_text .github/workflows/daily.yml '/public/stac/catalogs/default/collections/sample_roads/items?limit=1'
require_text .github/workflows/daily.yml 'demo: styled server map'
require_text .github/workflows/daily.yml 'style=roads-night'
require_text .github/workflows/daily.yml 'demo: named style document'
require_text .github/workflows/daily.yml '/public/styles/catalogs/default/styles/roads-night'
require_text index.html 'Seven visible paths.'
require_text index.html 'CQL2 filtering, STAC catalog views and server-rendered maps'
require_text index.html 'ESA WorldCover STAC → preserved COG and class metadata → Tellurion STAC/Features/raster Tiles'
require_text README.md 'ESA WorldCover STAC → preserved COG and class metadata → Tellurion STAC/Features/raster Tiles'
require_text README.md 'dynamic PNG tile composition, not a raster OGC API Maps conformance claim'

printf 'protocol gallery contract: ok\n'
