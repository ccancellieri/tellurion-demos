#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORKFLOWS="$ROOT/.github/workflows"
DAILY="$WORKFLOWS/daily.yml"

fail() {
  printf 'daily automation contract failed: %s\n' "$1" >&2
  exit 1
}

scheduled=$(grep -l '^[[:space:]]*schedule:' "$WORKFLOWS"/*.yml | wc -l | tr -d ' ')
test "$scheduled" = 1 || fail "expected exactly one scheduled workflow, found $scheduled"

test -f "$DAILY" || fail "missing .github/workflows/daily.yml"
test ! -f "$WORKFLOWS/smoke.yml" || fail "smoke.yml must be consolidated into daily.yml"
test ! -f "$WORKFLOWS/verify.yml" || fail "verify.yml must be consolidated into daily.yml"

if grep -Eq '^[[:space:]]+(push|pull_request):' "$DAILY"; then
  fail "daily.yml must not run automatically for pushes or pull requests"
fi

grep -Fq 'workflow_dispatch:' "$DAILY" || fail "daily.yml must retain manual dispatch"
grep -Fq 'cron: "17 6 * * *"' "$DAILY" || fail "daily.yml must run at 06:17 UTC"
grep -Fq 'group: daily-verification-and-deploy' "$DAILY" || fail "daily.yml must serialize daily verification"
grep -Fq 'cancel-in-progress: true' "$DAILY" || fail "daily.yml must cancel superseded attempts"

grep -Fq 'name: deployment and fixture contracts' "$DAILY" || fail "daily.yml is missing repository contracts"
grep -Fq 'name: public distribution manifest' "$DAILY" || fail "daily.yml is missing distribution verification"
grep -Fq 'name: ${{ matrix.demo }}' "$DAILY" || fail "daily.yml is missing live endpoint smoke checks"

render_services=$(grep -c '^[[:space:]]*-[[:space:]]*type: web' "$ROOT/render.yaml")
checks_pass=$(grep -c 'autoDeployTrigger: checksPass' "$ROOT/render.yaml")
test "$render_services" = 5 || fail "expected five Render web services, found $render_services"
test "$checks_pass" = "$render_services" || fail "every Render service must require passing checks"

printf 'Daily automation contract verified.\n'
