# OmaPiP

OmaPiP mirrors a selected Wayland window in a floating `ScreencopyView`.
It runs inside `omarchy-shell`; no helper, portal, or daemon is required.

## Install

```bash
omarchy plugin add https://github.com/Roddygithub/OmaPiP.git --enable
omarchy-shell shell summon io.github.roddygithub.omapip
```

Choose a window in the picker. The viewer can be moved and resized by the
compositor. To inspect the loaded source:

```bash
omarchy-shell shell call io.github.roddygithub.omapip status ''
```

The selected Hyprland address is never replaced implicitly. If that window is
destroyed, OmaPiP shows an unavailable state until the user selects another one.

V1 intentionally does not promise live geometric aspect-ratio locking or
multi-monitor/mixed-DPI policy. See [`docs/feasibility-report.md`](docs/feasibility-report.md)
for the validated architecture and accepted limitations.
