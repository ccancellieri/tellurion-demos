#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

require_file() {
  test -f "$ROOT/$1" || {
    printf 'missing required deployment file: %s\n' "$1" >&2
    exit 1
  }
}

require_text() {
  file=$1
  text=$2
  grep -Fq -- "$text" "$ROOT/$file" || {
    printf 'missing required text in %s: %s\n' "$file" "$text" >&2
    exit 1
  }
}

require_file Dockerfile
require_file render.yaml
require_file deploy/render/vector.yaml

require_text Dockerfile 'sha256sum -c'
require_text Dockerfile 'USER 10001:10001'
require_text Dockerfile 'ENTRYPOINT ["/app/tellurion"]'
require_text Dockerfile 'ARG DEMO_VERSION=v0.2.0'
require_text Dockerfile 'DEMO_ARCHIVE=tellurion-italy-demo-${DEMO_VERSION}.zip'
require_text Dockerfile 'rome-roads.geojson'
require_text Dockerfile 'grep -Fq '\''"applied":5603'\'' /tmp/rome-load.jsonl'

require_text render.yaml 'name: tellurion-vector-demo'
require_text render.yaml 'region: frankfurt'
require_text render.yaml 'plan: free'
require_text render.yaml 'healthCheckPath: /'
require_text render.yaml 'autoDeployTrigger: checksPass'
require_text render.yaml 'deploy/render/vector.yaml'

require_text deploy/render/vector.yaml 'driver: geopackage'
require_text deploy/render/vector.yaml 'id: sample_roads'
require_text deploy/render/vector.yaml 'url_env: TELLURION_GEOPACKAGE_PATH'
require_text demos/vector/index.html 'WebMercatorQuad/{z}/{y}/{x}.mvt'

python3 - "$ROOT/deploy/render/vector.yaml" <<'PY'
import sys

import yaml

with open(sys.argv[1], encoding="utf-8") as config_file:
    config = yaml.safe_load(config_file)

expected = "https://tellurion-vector-demo.onrender.com"
actual = config.get("server", {}).get("public_base_url")
if actual != expected:
    raise SystemExit(f"vector public_base_url must be {expected!r}, got {actual!r}")
PY

if grep -Eq 'routing:[[:space:]]*$|write:[[:space:]]' "$ROOT/deploy/render/vector.yaml"; then
  printf 'the public vector demo must not configure a write route\n' >&2
  exit 1
fi

if grep -Eq '(^|[[:space:]])PORT=[0-9]+' "$ROOT/Dockerfile"; then
  printf 'the container must accept Render\047s dynamic PORT instead of fixing one\n' >&2
  exit 1
fi

printf 'Render deployment contract verified.\n'
