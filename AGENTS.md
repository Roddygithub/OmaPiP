# OmaPiP agent instructions

- This repository is the research and future source tree for a native Omarchy plugin.
- Do not implement V1 until `docs/feasibility-report.md` is reviewed and explicitly approved.
- Probes are disposable experiments, not production code.
- Prefer local Omarchy, Quickshell, Hyprland, and Pi documentation over assumptions.
- Never modify `/usr/share/omarchy/` or user desktop configuration for a probe.
- Keep secrets and machine-specific artifacts out of Git.
- Record observed results as PASS/FAIL; do not infer untested behavior.
- After V1 work begins, never develop directly on `main`; use a short descriptive branch and a pull request.
- Inspect `git diff`, `git status`, and relevant checks before every commit and push; keep commits coherent.
- Never add secrets, credentials, personal data, generated artifacts, or machine-local files.
- Run relevant local checks before opening a PR; label Hyprland/Wayland checks as local integration tests.
- Monitor CI and fix failures before merge; never bypass protections or force-push `main`.
