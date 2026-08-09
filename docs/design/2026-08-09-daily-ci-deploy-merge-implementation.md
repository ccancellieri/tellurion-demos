# Daily verification, deployment, and merge implementation plan

**Goal:** Limit automatic hosted verification and Render deployment eligibility to one daily pipeline per repository, then integrate locally verified work and remove only worktrees whose commits are safely reachable from remote `main`.

**Architecture:** `tellurion-demos` will expose one scheduled workflow containing contract, distribution, and live-endpoint jobs. Tellurion keeps its existing daily workflow and local CI mirror. Existing changes are integrated sequentially with exact-head merges and post-merge reachability checks.

**Technology:** GitHub Actions YAML, POSIX shell contract tests, Git worktrees, Rust/Cargo verification, GitHub pull requests, Render Blueprint `checksPass` deployment gates.

## Global constraints

- At most one automatic hosted workflow run per repository per day.
- Manual dispatches and release-tag workflows are explicit exceptions.
- Render continues to deploy only after checks pass.
- Never modify or clean the user's principal Tellurion checkout.
- Never remove a worktree until its work is reachable from remote `main`.
- Merge requests use an expected head SHA and fail if the branch moved.
- No force push or history rewrite.

## Task 1: Pin the demos automation contract

**Files:**

- Create: `tests/daily_automation_contract.sh`

- [ ] Write a shell contract that requires exactly one scheduled workflow, rejects `push` and `pull_request` triggers from it, requires `workflow_dispatch`, checks the three job names, and requires every Render service to retain `autoDeployTrigger: checksPass`.
- [ ] Run `sh tests/daily_automation_contract.sh` and verify it fails because `smoke.yml` and `verify.yml` still define separate automatic paths.
- [ ] Keep the failing output as the red evidence for Task 2.

The core assertions are:

```sh
scheduled=$(grep -l '^[[:space:]]*schedule:' .github/workflows/*.yml | wc -l | tr -d ' ')
test "$scheduled" = 1
test -f .github/workflows/daily.yml
test ! -f .github/workflows/smoke.yml
test ! -f .github/workflows/verify.yml
! grep -Eq '^[[:space:]]+(push|pull_request):' .github/workflows/daily.yml
grep -Fq 'workflow_dispatch:' .github/workflows/daily.yml
grep -Fq 'name: deployment and fixture contracts' .github/workflows/daily.yml
grep -Fq 'name: public distribution manifest' .github/workflows/daily.yml
grep -Fq 'name: ${{ matrix.demo }}' .github/workflows/daily.yml
test "$(grep -c 'autoDeployTrigger: checksPass' render.yaml)" = 5
```

## Task 2: Consolidate demos verification and smoke checks

**Files:**

- Create: `.github/workflows/daily.yml`
- Delete: `.github/workflows/verify.yml`
- Delete: `.github/workflows/smoke.yml`
- Modify: `tests/daily_automation_contract.sh`

- [ ] Build `daily.yml` from the current remote-main job bodies without changing their test commands or endpoint contracts.
- [ ] Configure only `schedule` at `17 6 * * *` and `workflow_dispatch` triggers.
- [ ] Add workflow concurrency group `daily-verification-and-deploy` with `cancel-in-progress: true`.
- [ ] Invoke `sh tests/daily_automation_contract.sh` as the first contracts step after checkout.
- [ ] Run `sh tests/daily_automation_contract.sh`; expect success.
- [ ] Run `python3 -m unittest -v tests.test_harvest_esa_worldcover`; expect all tests to pass.
- [ ] Run every `tests/render_*_contract.sh`; expect all contracts to pass.
- [ ] Run a local HTTP server and verify the gallery and seven demo pages with the same commands as the workflow.
- [ ] Run `git diff --check` and scan the staged diff for personal data, credentials, session identifiers, and unwanted attribution.
- [ ] Commit as `Run demos verification once daily`.

## Task 3: Publish and merge the demos automation change

**Interfaces:**

- Consumes: clean commit from Task 2.
- Produces: merged demos PR and remote-main SHA containing the daily workflow.

- [ ] Push `ops/daily-verification-gate` without force.
- [ ] Open a PR against `main` describing the one-run-per-day contract and local verification.
- [ ] Re-read PR metadata and compare its head SHA to the verified local commit.
- [ ] Squash-merge using the expected head SHA.
- [ ] Verify the PR is merged and remote `main` contains `.github/workflows/daily.yml` with the expected triggers.

## Task 4: Integrate Tellurion PR #300

**Worktree:** `/private/tmp/tellurion-issue215-integration`

- [ ] Confirm clean branch `cc/dynamic-control-plane-integration` at `b7ac416844b8a92ed438da6bfe085111c3bb0627`.
- [ ] Run the affected core policy/model/path, store, bootstrap, middleware, SQLite, and non-live PostgreSQL suites documented in PR #300.
- [ ] Run formatting, strict clippy for affected crates, server binary check, `git diff --check`, and hygiene scans.
- [ ] Re-read PR #300 and require `mergeable: true` with the same head SHA.
- [ ] Squash-merge PR #300 using that expected SHA.
- [ ] Verify the merged PR and remote-main reachability before removing either issue-215 worktree.

## Task 5: Update and integrate Tellurion PR #259

**Worktree:** `/Users/ccancellieri/work/code/_worktrees/tellurion-cog-mosaic`

- [ ] Fetch current remote `main` without changing the principal checkout.
- [ ] Merge current `origin/main` into `feat/cog-mosaic`; resolve only conflicts caused by upstream evolution.
- [ ] Run `cargo fmt --all --check`.
- [ ] Run `cargo test -p tellurion-cog --locked`.
- [ ] Run `cargo test -p tellurion --no-default-features --features cog --test cog_binary --locked`.
- [ ] Run strict clippy for `tellurion-cog` and the standalone `cog` server feature.
- [ ] Verify the standalone dependency tree still excludes PostGIS, DuckDB, PostgreSQL/deadpool, and GDAL packages.
- [ ] Push the updated branch without force, mark PR #259 ready, and verify its exact head SHA and mergeability.
- [ ] Squash-merge PR #259 using the expected head SHA.
- [ ] Verify remote-main reachability before cleanup.

## Task 6: Integrate the Italy WorldCover demos branch

**Worktree:** `/Users/ccancellieri/work/code/_worktrees/tellurion-demos-italy-mosaic`

- [ ] Update `feat/italy-worldcover-mosaic` from the new demos `main` without losing its unpushed commits.
- [ ] Verify the Italy harvest unit suite, deployment contracts, gallery contracts, manifest digests, and `git diff --check`.
- [ ] Push the complete branch without force and open a PR against `main`.
- [ ] Verify the exact head SHA and mergeability, then squash-merge.
- [ ] Verify remote-main reachability.

## Task 7: Clean merged auxiliary worktrees

- [ ] Confirm demos PR #18 is merged and `launch/stac-harvest-content` is behind remote `main` with zero unique commits.
- [ ] Remove the merged STAC harvest worktree.
- [ ] Remove the two issue-215 worktrees only after PR #300 is verified merged.
- [ ] Remove the COG mosaic worktree only after PR #259 is verified merged.
- [ ] Remove the Italy mosaic worktree only after its PR is verified merged.
- [ ] Prune stale worktree registrations.
- [ ] Delete local auxiliary branches with normal deletion only when Git considers them merged; otherwise preserve them and report why.
- [ ] Remove merged remote branches where safe.
- [ ] Report disk space before and after cleanup and confirm the principal Tellurion checkout is unchanged.

## Task 8: Final verification

- [ ] Confirm no auxiliary worktree remains for completed work.
- [ ] Confirm Tellurion has no open PR from the inventoried auxiliary work.
- [ ] Confirm tellurion-demos has no open PR from the inventoried auxiliary work.
- [ ] Confirm remote Tellurion retains its daily CI trigger and remote demos contains exactly one daily workflow.
- [ ] Confirm all linked issues closed by the merged PRs have the expected final state.
