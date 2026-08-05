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
require_file docs/articles/from-one-cog-to-italy.md
require_file docs/articles/from-stac-discovery-to-a-live-map.md
require_file docs/social/esa-worldcover-stac-harvest-linkedin.md
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
require_text docs/articles/from-stac-discovery-to-a-live-map.md 'ESA_WorldCover_10m_2021_v200_N39E012'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '41,236,803 bytes'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '8370f37c0ffadd33fff59473c633a827653c14f1d46c4175ed07b77efbf17aa5'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '5d951afb19e5fdcb90773bac374b556d425f8945ba4b719114c7f7b03157464a'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '## Italy expansion — 2026-08-05'
require_text docs/articles/from-stac-discovery-to-a-live-map.md 'deployment is pending'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '../design/2026-08-05-italy-worldcover-mosaic-design.md'
require_text docs/articles/from-stac-discovery-to-a-live-map.md '../../data/stac/esa-worldcover-italy/manifest.json'
require_text docs/articles/from-stac-discovery-to-a-live-map.md 'https://github.com/ccancellieri/tellurion/pull/259'
require_text docs/articles/from-stac-discovery-to-a-live-map.md 'from-one-cog-to-italy.md'
require_text docs/articles/from-one-cog-to-italy.md 'Italy first, 10 m underneath'
require_text docs/articles/from-one-cog-to-italy.md '17 ESA WorldCover 2021 v200 source Items'
require_text docs/articles/from-one-cog-to-italy.md 'complete pinned GISCO Italy geometry'
require_text docs/articles/from-one-cog-to-italy.md '889,726,110 bytes'
require_text docs/articles/from-one-cog-to-italy.md '381ac0bb927b0a3014134ac472c627ddf95a1b7c7ed01fbb9ede9f4916f92c49'
require_text docs/articles/from-one-cog-to-italy.md '7b1499635f5463b8e2a510b8d6f4f6a3a6ae0b494dc0e15eed48bcd02fcdbedf'
require_text docs/articles/from-one-cog-to-italy.md '5c0019d82d9c54dae8e6b6c1b5a97198c6c67e66fa110b1b55a2ed4b527c5c9e'
require_text docs/articles/from-one-cog-to-italy.md 'Deployment pending'
require_text docs/articles/from-one-cog-to-italy.md '/public/stac/catalogs/default/collections/esa_worldcover_2021_italy'
require_text docs/articles/from-one-cog-to-italy.md '/public/features/catalogs/default/collections/esa_worldcover_2021_italy/items?limit=1'
require_text docs/articles/from-one-cog-to-italy.md '/public/tiles/catalogs/default/collections/esa_worldcover_2021_italy/tiles/WebMercatorQuad'
require_text docs/articles/from-one-cog-to-italy.md 'request-time STAC federation'
require_text docs/articles/from-one-cog-to-italy.md 'OGC API Maps conformance'
require_text docs/articles/from-one-cog-to-italy.md 'benchmark'
require_text docs/articles/from-one-cog-to-italy.md 'ESA WorldCover CC BY 4.0'
require_text docs/articles/from-one-cog-to-italy.md 'Non-commercial use; © EuroGeographics for the administrative boundaries'
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
require_text .github/workflows/daily.yml 'python3 -m unittest -v tests.test_harvest_esa_worldcover tests.test_harvest_esa_worldcover_italy'
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
require_text .github/workflows/daily.yml 'demo: Italy STAC Collection'
require_text .github/workflows/daily.yml 'demo: Italy FeatureCollection'
require_text .github/workflows/daily.yml 'demo: Italy raster TileSet'
require_text .github/workflows/daily.yml 'demo: Italy country PNG tile'
require_text .github/workflows/daily.yml 'demo: Italy Milan PNG tile'
require_text .github/workflows/daily.yml 'demo: Italy Venice PNG tile'
require_text .github/workflows/daily.yml 'demo: Italy Rome PNG tile'
require_text .github/workflows/daily.yml 'demo: Italy Naples PNG tile'
require_text .github/workflows/daily.yml 'demo: Italy Palermo PNG tile'
require_text .github/workflows/daily.yml '/public/stac/catalogs/default/collections/esa_worldcover_2021_italy'
require_text .github/workflows/daily.yml '/public/features/catalogs/default/collections/esa_worldcover_2021_italy/items?limit=1'
require_text .github/workflows/daily.yml '/public/tiles/catalogs/default/collections/esa_worldcover_2021_italy/tiles/WebMercatorQuad'
require_text .github/workflows/daily.yml '/5/11/17.png'
require_text .github/workflows/daily.yml '/13/2931/4305.png'
require_text .github/workflows/daily.yml '/13/2932/4376.png'
require_text .github/workflows/daily.yml '/13/3043/4380.png'
require_text .github/workflows/daily.yml '/13/3075/4420.png'
require_text .github/workflows/daily.yml '/13/3156/4400.png'
python3 - <<'PY'
from pathlib import Path

import yaml

workflow = yaml.safe_load(Path('.github/workflows/daily.yml').read_text())
jobs = workflow['jobs']
live_entries = jobs['live-endpoints']['strategy']['matrix']['include']
national_job = jobs.get('italy-endpoints')
failures = []

if len([entry for entry in live_entries if 'esa_worldcover_2021_rome' in entry['url']]) != 4:
    failures.append('the four legacy Rome entries must remain active')
if not all('esa_worldcover_2021_italy' not in entry['url'] for entry in live_entries):
    failures.append('national entries must not run in the live-endpoints job')
if national_job is None:
    failures.append('national entries need an explicitly gated italy-endpoints job')
else:
    national_entries = national_job['strategy']['matrix']['include']
    if national_job.get('if') != "${{ vars.ITALY_WORLDCOVER_SMOKE_ENABLED == 'true' }}":
        failures.append('national job must be gated by ITALY_WORLDCOVER_SMOKE_ENABLED')
    if len(national_entries) != 9:
        failures.append('national matrix must retain exactly nine entries')
    if not all('esa_worldcover_2021_italy' in entry['url'] for entry in national_entries):
        failures.append('national matrix entries must retain national URLs')

article = Path('docs/articles/from-one-cog-to-italy.md').read_text()
evidence_boundary = 'Desktop/browser and 390x844 mobile country/city evidence remain pending until deployment and post-deployment verification.'
if evidence_boundary not in article:
    failures.append('national article must explicitly leave desktop/browser and 390x844 mobile country/city evidence pending')

if failures:
    raise SystemExit('\n'.join(failures))
PY
require_text index.html 'Seven visible paths.'
require_text index.html 'CQL2 filtering, STAC catalog views and server-rendered maps'
require_text index.html 'Italy-wide ESA WorldCover mosaic'
require_text index.html 'country-to-neighbourhood coverage through one Tellurion TileSet'
require_text index.html 'deployment is pending'
require_text README.md 'Italy-wide ESA WorldCover mosaic'
require_text README.md 'country-to-neighbourhood coverage through one Tellurion TileSet'
require_text README.md 'deployment is pending'
require_text README.md 'Non-commercial use; © EuroGeographics for the administrative boundaries'
require_text README.md 'dynamic PNG tile composition, not a raster OGC API Maps conformance claim'
require_text README.md 'Hosted response times are not benchmark evidence.'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md '## Original Rome launch copy'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md '## Italy expansion follow-up — publish only after live endpoint/evidence verification'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md '17 source COGs'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md '889,726,110 bytes'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md 'No request-time STAC federation'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md 'not OGC API Maps conformance'
require_text docs/social/esa-worldcover-stac-harvest-linkedin.md 'from-one-cog-to-italy.md'

printf 'protocol gallery contract: ok\n'
