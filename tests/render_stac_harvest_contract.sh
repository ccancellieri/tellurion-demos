#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DOCKERFILE="$ROOT/Dockerfile.stac-harvest"
CONFIG="$ROOT/deploy/render/stac-harvest.yaml"
RENDER="$ROOT/render.yaml"
WORKFLOW="$ROOT/.github/workflows/daily.yml"
MANIFEST="$ROOT/data/stac/esa-worldcover/manifest.json"
COLORMAP="$ROOT/data/stac/esa-worldcover/colormap.yaml"

require_file() {
  if [ ! -f "$1" ]; then
    printf 'missing required file: %s\n' "$1" >&2
    exit 1
  fi
}

require_text() {
  if ! grep -Fq "$2" "$ROOT/$1"; then
    printf 'missing required text in %s: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

require_file "$DOCKERFILE"
require_file "$CONFIG"
require_file "$RENDER"
require_file "$WORKFLOW"
require_file "$MANIFEST"
require_file "$COLORMAP"

require_text Dockerfile.stac-harvest 'ARG TELLURION_VERSION=v0.3.0'
require_text Dockerfile.stac-harvest 'sha256sum -c'
require_text Dockerfile.stac-harvest 'ogr2ogr -f GPKG'
require_text Dockerfile.stac-harvest 'USER 10001:10001'
require_text Dockerfile.stac-harvest 'TELLURION_GEOPACKAGE_PATH=/app/data/worldcover.gpkg'
require_text Dockerfile.stac-harvest 'cargo build --release --locked -p tellurion --no-default-features --features cog,geopackage'
require_text Dockerfile.stac-harvest 'chmod 0755 /app/data'
require_text Dockerfile.stac-harvest 'chmod 0644 /app/data/worldcover.gpkg'
require_text Dockerfile.stac-harvest 'COPY --chown=10001:10001 --from=data-builder /app/data /app/data'
require_text deploy/render/stac-harvest.yaml 'features: harvested_items'
require_text deploy/render/stac-harvest.yaml 'tiles: harvested_cog'
require_text deploy/render/stac-harvest.yaml 'source_item_id'
require_text deploy/render/stac-harvest.yaml '{ name: start_datetime, type: string }'
require_text deploy/render/stac-harvest.yaml '{ name: end_datetime, type: string }'
require_text render.yaml 'name: tellurion-stac-harvest-demo'
require_text .github/workflows/daily.yml 'tests/render_stac_harvest_contract.sh'

if grep -Eq 'write:[[:space:]]' "$CONFIG"; then
  printf 'the STAC harvest demo must not configure a write route\n' >&2
  exit 1
fi

if grep -Fq 'colormap:' "$CONFIG"; then
  printf 'the paletted WorldCover COG must use its embedded colormap\n' >&2
  exit 1
fi

manifest_url=$(python3 - "$MANIFEST" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as manifest_file:
    print(json.load(manifest_file)["served_asset"]["href"])
PY
)
image_url=$(sed -n 's/^ENV TELLURION_COG_URL=//p' "$DOCKERFILE" | head -n 1)

if [ -z "$manifest_url" ] || [ "$manifest_url" != "$image_url" ]; then
  printf 'the served COG URL must exactly match the committed manifest\n' >&2
  exit 1
fi

require_text data/stac/esa-worldcover/manifest.json '"relationship": "byte-identical-official-mirror"'
require_text data/stac/esa-worldcover/manifest.json '"sha256": "5d951afb19e5fdcb90773bac374b556d425f8945ba4b719114c7f7b03157464a"'

case "$image_url" in
  *\?*|*sig=*|*token=*|*se=*)
    printf 'the image COG URL must be public and unsigned\n' >&2
    exit 1
    ;;
esac

for property in source_item_id start_datetime end_datetime product_version grid_code; do
  require_text deploy/render/stac-harvest.yaml "$property"
done

for asset in source_cog source_snapshot provenance_manifest; do
  require_text deploy/render/stac-harvest.yaml "$asset"
done

for stop in \
  '{ value: 0.0, rgba: [0, 0, 0, 0] }' \
  '{ value: 10.0, rgba: [0, 100, 0, 255] }' \
  '{ value: 20.0, rgba: [255, 187, 34, 255] }' \
  '{ value: 30.0, rgba: [255, 255, 76, 255] }' \
  '{ value: 40.0, rgba: [240, 150, 255, 255] }' \
  '{ value: 50.0, rgba: [250, 0, 0, 255] }' \
  '{ value: 60.0, rgba: [180, 180, 180, 255] }' \
  '{ value: 70.0, rgba: [240, 240, 240, 255] }' \
  '{ value: 80.0, rgba: [0, 100, 200, 255] }' \
  '{ value: 90.0, rgba: [0, 150, 160, 255] }' \
  '{ value: 95.0, rgba: [0, 207, 117, 255] }' \
  '{ value: 100.0, rgba: [250, 230, 160, 255] }'; do
  require_text data/stac/esa-worldcover/colormap.yaml "$stop"
done

printf 'render STAC harvest contract passed\n'
