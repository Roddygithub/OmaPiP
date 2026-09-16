# OmaPiP — GitHub governance

## GITHUB ENVIRONMENT

Git version: 2.55.0

GitHub CLI version: 2.100.0

Authenticated GitHub user: `Roddygithub` (admin on repository; token scopes observed: `gist`, `read:org`, `repo`, `workflow`; no `read:project`)

Repository: `Roddygithub/OmaPiP`

Visibility: public

Default branch: `main`

## REPOSITORY SETTINGS

Description: PASS — `Universal live mirror Picture-in-Picture plugin for Omarchy`

Topics: PASS — explicitly audited; none configured. None added because the project is not yet released and no useful stable taxonomy was identified.

Issues: ENABLED

Projects: ENABLED (existence/access details not fully queryable with the current token because GitHub requires `read:project` for GraphQL project fields)

Wiki: ENABLED — left unchanged; no wiki content yet.

Discussions: DISABLED — left unchanged; too early for a separate forum.

License: MIT — selected by the project owner and published in `LICENSE`.

Merge methods: squash only. Merge commits and rebase merges disabled.

Auto-merge: disabled; no CI exists yet, so there is no useful automation to wait for.

Delete head branches: enabled.

Actions enabled: yes; no workflows currently exist.

Actions permissions: selected actions only (GitHub-owned and verified actions); workflow `GITHUB_TOKEN` default permission is read, and workflows cannot approve pull requests. SHA pinning is not globally required by the current setting; future workflows must pin third-party actions to full commit SHAs.

## MAIN PROTECTION

Ruleset present: YES — active repository ruleset `Protect main`.

Main protected: YES — modern repository ruleset, not legacy branch protection.

Direct push allowed: NO — pull request rule applies to `refs/heads/main`.

Force push allowed: NO — `non_fast_forward` rule.

Branch deletion allowed: NO — `deletion` rule.

PR required: YES.

Required status checks: none currently; intentionally none because no CI workflow exists.

Required approvals: 0 — solo-maintainer workflow remains possible. This is not a review bypass for future contributors; it simply does not make the owner's PR unmergeable.

The ruleset has no bypass actor (`current_user_can_bypass: never`). It was read back successfully after creation. No destructive push/delete test was attempted.

## GITHUB ACTIONS

Workflows: none.

Checks currently enforced: none.

Security review: safe baseline applied — Actions remain enabled but restricted to selected trusted action classes; default token is read-only and cannot approve PRs. No `pull_request_target`, secrets, environments, or third-party actions introduced.

Recommended next CI, after production code exists: one small `pull_request` workflow for JSON/manifest validation, `qmllint` if the runner can install the matching tool, and repository hygiene. Real Hyprland/Wayland tests stay LOCAL / INTEGRATION TEST.

## GOVERNANCE FILES

PR template: USED — short template now committed in `.github/PULL_REQUEST_TEMPLATE.md`.

Issue templates: NOT NEEDED YET — no recurring issue taxonomy exists yet.

CONTRIBUTING: NOT NEEDED YET — `AGENTS.md` covers the current solo workflow; add a concise public contributor guide when external contributions begin.

SECURITY: USED — `SECURITY.md` gives private reporting guidance and documents the unsandboxed shell boundary.

CODEOWNERS: NOT NEEDED YET — one owner and no review requirement; adding it now would add no enforcement value.

Dependabot: NOT NEEDED YET — no dependency manifest exists; no `.github/dependabot.yml` added.

LICENSE: USED — MIT license published after explicit owner approval.

## GIT HYGIENE

.gitignore reviewed: PASS — excludes Pi sessions/npm, Node artifacts, logs, probe output, secrets, and common temporary files.

Secrets check: PASS — repository contents and commits were scanned for obvious tokens/private keys; GitHub secret scanning and push protection are enabled.

Commit metadata reviewed: PASS — existing commits expose `Roland Salardon <r.salardon@gmail.com>`. Future commits in this repository now use the local-only GitHub noreply address `3160144+Roddygithub@users.noreply.github.com`; global Git configuration remains unchanged.

Commit signing strategy: not configured; current commits are unsigned (`verification: null`). No signing setup changed. Consider SSH signing before a broader contribution phase.

Branch strategy: after V1 starts: short descriptive branch from `main` → atomic commits → inspect diff/status → push → PR → CI/review → squash merge → automatic head-branch deletion.

Merge strategy: squash merge only, for one readable commit per change; no merge commits or rebase merge exposed in the repository UI.

## AGENT WORKFLOW

Agent Git/GitHub rules persisted: YES — concise operational rules added to `AGENTS.md`.

Fresh Pi session understands GitHub workflow: YES — Pi already loads `AGENTS.md`; governance decisions and human decisions are recorded here.

## OUTCOME

Changes made:

- Added active `Protect main` repository ruleset: PR required, no force-push, no deletion, zero required approvals.
- Restricted Actions to selected trusted actions and read-only workflow tokens.
- Enabled automatic deletion of merged head branches.
- Enabled squash-only merge strategy.
- Added PR template and security policy.
- Added concise Git/GitHub rules to `AGENTS.md`.
- Published the owner-approved MIT license.
- Configured the repository-local future commit email.

Settings changed: repository merge methods, automatic branch deletion, Actions permission baseline, main ruleset.

Files created: `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `LICENSE`, `docs/github-governance.md`, and additional probe files.

Files modified: `AGENTS.md`; later report/probe updates were delivered in PR #2.

Commits created: PR #1 squash-merged as `6e6c4cd`; PR #2 squash-merged as `0802158`.

Branch: `main` (current repository state; the two setup changes were delivered through PRs #1 and #2; future V1 work must use PRs).

PR created: PR #1 and PR #2 were created, CI-free checks were empty, squash-merged, and their head branches were deleted.

GitHub checks: no workflows/checks currently exist.

Known limitations: project GraphQL details unavailable without `read:project`; no CI yet; commits unsigned; no multi-maintainer review policy; no destructive protection test performed.

Human decisions required:

NONE — MIT was approved and published. A fuller Projects audit would require optional `read:project`, but no decision is needed for the current setup.

`GITHUB_READY: YES`

The V1 implementation and the remaining technical probes were not started.
