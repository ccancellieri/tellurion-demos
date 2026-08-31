#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

require_file() {
  test -f "$1" || { printf 'missing required file: %s\n' "$1" >&2; exit 1; }
}

require_text() {
  grep -Fq "$2" "$1" || { printf 'missing required text in %s: %s\n' "$1" "$2" >&2; exit 1; }
}

reject_text() {
  if grep -Fq "$2" "$1"; then
    printf 'forbidden text in %s: %s\n' "$1" "$2" >&2
    exit 1
  fi
}

require_file docs/index.html
require_file docs/docs.css
require_file docs/search.js
require_file tests/static_site_links.py
require_file tests/fixtures/docs_external_links.txt

require_text index.html 'href="docs/"'
require_text index.html '>Documentation<'
require_text index.html 'Start with the field guide'
require_text index.html 'class="skip-link"'
require_text index.html '<main id="main-content">'

require_text docs/index.html '<title>Tellurion documentation'
require_text docs/index.html 'class="skip-link"'
require_text docs/index.html '<main id="main-content"'
require_text docs/index.html 'aria-label="Documentation sections"'
require_text docs/index.html 'aria-current="page"'
reject_text docs/index.html 'href="#overview" aria-current="page"'
require_text docs/index.html 'No verified public v0.4 binary is available yet.'
require_text docs/index.html '>Available<'
require_text docs/index.html '>Optional<'
require_text docs/index.html '>Preview<'
require_text docs/index.html '>Planned<'
require_text docs/index.html 'What is not supported'
require_text docs/index.html 'Build from source'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/quickstart/install.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/licensing.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/deployment-topologies.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/quickstart/real-data-osm-geopackage.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/quickstart/qgis.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/blob/main/docs/spec-deviations.md'
require_text docs/index.html 'https://github.com/ccancellieri/tellurion/releases'
require_text docs/index.html 'source archive is not an installable Tellurion binary'
require_text docs/index.html 'Product evidence: Tellurion source revision <code>3eb31a872b74</code>'
require_text docs/index.html 'Documentation snapshot: 2026-08-31'
require_text docs/index.html 'Next / Preview'
require_text docs/index.html 'Shapefile ZIP'
require_text docs/index.html 'Server wiring, vector tiles and a public demo remain incomplete.'
require_text docs/index.html 'configured, bounded 2D <code>x/y</code> slice'
require_text docs/index.html '<table class="driver-table">'
for driver in PostGIS GeoPackage PMTiles FlatGeobuf GeoParquet COG Zarr Iceberg DuckDB Shapefile; do
  require_text docs/index.html ">$driver<"
done
require_text docs/index.html 'id="docs-search"'
require_text docs/index.html 'aria-keyshortcuts="/"'
require_text docs/index.html '<dialog id="search-dialog"'
require_text docs/index.html 'src="search.js"'
require_text docs/search.js 'event.key === "/"'
require_text docs/search.js 'event.key === "Escape"'
require_text docs/search.js 'event.key !== "Tab"'
require_text docs/search.js 'h2, h3, .matrix article, .manuals a'

reject_text docs/index.html 'tellurion-v0.4.0-aarch64-apple-darwin.tar.gz'
reject_text docs/index.html 'tellurion-v0.4.0-x86_64-unknown-linux-musl.tar.gz'
reject_text docs/index.html 'tellurion-v0.4.0-x86_64-pc-windows-msvc.zip'
reject_text docs/index.html 'tellurion-v0.4.0-source-28fb41c.zip'
reject_text docs/index.html 'dist/tellurion-v0.4.0-source'

require_text docs/docs.css ':focus-visible'
require_text docs/docs.css '@media (max-width: 760px)'
require_text docs/docs.css '.docs-nav'
require_text docs/docs.css '.driver-table'

printf 'documentation contract: ok\n'
