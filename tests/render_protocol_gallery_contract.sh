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
require_text demos/stac/index.html '/public/stac/catalogs/default/collections/sample_roads/items'
require_text demos/stac/index.html 'not an asset-catalog demonstration'
require_text demos/maps/index.html '/public/tiles/catalogs/default/collections/sample_roads/map?'
require_text demos/maps/index.html '/public/styles/catalogs/default/styles/roads-night'
require_text demos/maps/index.html 'OGC API — Styles is a draft'
require_text demos/query/index.html 'const statusBox = document.getElementById("status");'
require_text demos/stac/index.html 'const statusBox = document.getElementById("status");'
require_text demos/maps/index.html 'const statusBox = document.getElementById("status");'

for page in query stac maps; do
  require_text index.html "demos/$page/"
  require_text README.md "demos/$page/"
done

require_text .github/workflows/verify.yml 'sh tests/render_protocol_gallery_contract.sh'
require_text .github/workflows/verify.yml 'for page in vector raster zarr 3d query stac maps'
require_text .github/workflows/smoke.yml 'demo: CQL2 feature filter'
require_text .github/workflows/smoke.yml 'filter-lang=cql2-text'
require_text .github/workflows/smoke.yml 'demo: STAC feature projection'
require_text .github/workflows/smoke.yml '/public/stac/catalogs/default/collections/sample_roads/items?limit=1'
require_text .github/workflows/smoke.yml 'demo: styled server map'
require_text .github/workflows/smoke.yml 'style=roads-night'
require_text .github/workflows/smoke.yml 'demo: named style document'
require_text .github/workflows/smoke.yml '/public/styles/catalogs/default/styles/roads-night'
require_text index.html 'Seven visible paths.'
require_text index.html 'CQL2 filtering, STAC catalog views and server-rendered maps'

printf 'protocol gallery contract: ok\n'
