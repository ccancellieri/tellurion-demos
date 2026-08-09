# Daily verification, deployment, and local merge design

## Goal

Keep hosted execution bounded to one automatic pipeline per repository per day while retaining trustworthy local merge gates and predictable Render deployments.

## Scope

- `ccancellieri/tellurion` keeps its existing daily hosted CI schedule.
- `ccancellieri/tellurion-demos` combines repository verification and public endpoint smoke checks into one daily workflow.
- Manual workflow dispatches and version-tag release workflows are explicit operator actions and are not part of the automatic daily allowance.
- Render services continue using `autoDeployTrigger: checksPass`; the latest `main` commit becomes deployable only after the daily combined workflow succeeds.

## Hosted workflow contract

The demos repository has one automatic trigger:

```yaml
on:
  schedule:
    - cron: "17 6 * * *"
  workflow_dispatch:
```

The workflow contains three independent jobs:

1. repository and fixture contracts;
2. public distribution manifest verification;
3. live public endpoint smoke tests.

There are no `push` or `pull_request` triggers. Several commits may therefore accumulate during a day, but only the latest default-branch commit is verified by the scheduled run. Concurrency cancels an older daily/manual attempt when a newer attempt starts.

## Local merge gate

Hosted CI is an independent daily cross-check, not the per-PR merge gate while account-funded runners are unavailable. A PR may be merged only when all of these facts hold for its exact head SHA:

1. the branch and worktree are clean;
2. the documented local test, formatting, lint, and contract commands have passed on that SHA;
3. the PR is mergeable against current `main`;
4. no unresolved review finding applies to the head;
5. the merge request names the verified SHA, preventing a moved branch from being merged accidentally.

Integration is sequential. Engine changes merge before demo changes that depend on them. A stale or conflicting branch is first updated from current `main`, then its local gate is repeated.

## Existing work order

1. Merge Tellurion PR #300 after confirming its existing local evidence still matches the unchanged head.
2. Update Tellurion PR #259 from current `main`, repeat its scoped local gate, mark it ready, and merge it.
3. Open, verify, and merge the Italy WorldCover demos branch after #259 is available on Tellurion `main`.
4. Treat the STAC harvest demos branch as already integrated through PR #18.

## Cleanup and recovery

A worktree is removed only after the corresponding commit is reachable from the repository's remote `main`. Tracked branches are deleted only after that reachability check. Build directories are disposable and may be cleaned earlier to control disk usage.

The user's principal Tellurion checkout is excluded from all merge and cleanup operations because it contains independent local commits and a modified README. Cleanup targets only the explicitly inventoried auxiliary worktrees.

If verification or mergeability fails, the worktree and branch remain intact and the failure is reported. No force push, history rewrite, or destructive checkout is part of this process.
