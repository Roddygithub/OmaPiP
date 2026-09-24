# OmaPiP

Picture-in-Picture for any Wayland window on Omarchy.

## Why OmaPiP?

Keep any window visible while you work — a video, a dashboard, a build log, a video call, or a reference document. The source window stays exactly where it is; OmaPiP mirrors it into a floating, always-on-top viewer that you can move, resize, and pin across workspaces.

## Features

- **Any selectable Wayland window** — pick from a live list of open windows
- **Keyboard-navigable picker** — arrow to a source, Enter to capture, Esc to dismiss
- **Native Omarchy bar widget** — one-click access from the bar
- **Floating always-visible viewer** — pinned across workspaces, raised above normal windows
- **Freeform move and resize** — drag anywhere to move; drag any edge or corner to resize (no aspect-ratio lock)
- **Fill / Fit / Stretch rendering** — three display modes, cycled from the toolbar
- **Change source without reopening** — *Choose* reopens the picker while capture continues
- **Exact source identity** — tracked by Hyprland address, not fragile titles
- **Explicit unavailable-source handling** — clear prompt when the source window is closed
- **No helper daemon** — runs entirely inside `omarchy-shell` as QML
- **No administrator privileges** — user-level only
- **No capture persistence** — pixels are never written to disk by OmaPiP

## Quick Start

```bash
omarchy plugin add https://github.com/Roddygithub/OmaPiP.git --enable
```

1. Click the **OmaPiP** bar icon in the right section
2. Select a window from the picker
3. Drag the viewer to position it
4. Drag any edge or corner to resize freely
5. Click **Fill** to cycle Fill → Fit → Stretch
6. Click **Choose** to pick a different window
7. Click **Close** to hide the viewer (source window is unaffected)

## Controls

| Action | Result |
|--------|--------|
| ↑ / ↓ in picker | Move keyboard selection (clamped at both ends) |
| Home / End in picker | Jump to the first / last source |
| Enter in picker | Open the focused source (same path as a click) |
| Esc in picker | Close picker only; an open viewer keeps running |
| Left-click + drag on viewer | Move viewer freely (native compositor move) |
| Drag any edge / corner | Resize freely (8 edges, native compositor resize) |
| Click **Fill** button | Cycle display mode: Fill → Fit → Stretch |
| Click **Choose** | Reopen source picker (capture continues) |
| Click **Close** | Close viewer only; source window unaffected |
| Right-click on viewer | Reopen source picker |
| Source window destroyed | Toolbar shows "Choose another window" |

## Display Modes

| Mode | Behavior |
|------|----------|
| **Fill** (default) | Preserve aspect ratio, crop to cover the entire viewer (like `background-size: cover`) |
| **Fit** | Preserve aspect ratio, show entire source; letterboxing may appear (like `background-size: contain`) |
| **Stretch** | Fill viewer exactly; distortion possible |

The viewer keeps its geometry when switching sources or display modes.

## Requirements

- Omarchy with the Quickshell plugin runtime
- Hyprland
- Quickshell with `ScreencopyView` support
- A Wayland session

No minimum versions are enforced beyond what Omarchy itself requires.

## Privacy & Security

- No network access from OmaPiP itself
- No authentication, secrets, or credentials
- No administrator privileges required
- No external helper, daemon, or portal (PipeWire, xdg-desktop-portal)
- Captured frames are not persisted to disk by OmaPiP
- Selected Hyprland address is session state only; never written to config files

See [SECURITY.md](SECURITY.md) for the vulnerability reporting policy and security boundaries.

## Install / Update / Remove

```bash
# Install and enable
omarchy plugin add https://github.com/Roddygithub/OmaPiP.git --enable

# Update (when a new release is published)
omarchy plugin update io.github.roddygithub.omapip --yes

# Disable temporarily
omarchy plugin disable io.github.roddygithub.omapip

# Remove completely
omarchy plugin remove io.github.roddygithub.omapip --yes
```

## CLI / Advanced Use

```bash
# Summon via shell (secondary path)
omarchy-shell shell summon io.github.roddygithub.omapip '{}'

# Inspect internal state (JSON)
omarchy-shell io.github.roddygithub.omapip status

# List available sources (JSON)
omarchy-shell io.github.roddygithub.omapip sources

# Select a specific Hyprland address (bare hex and 0x-prefixed forms are accepted)
omarchy-shell io.github.roddygithub.omapip select '0x123456'

# Reopen picker
omarchy-shell io.github.roddygithub.omapip chooseAnother

# Programmatic placement
omarchy-shell io.github.roddygithub.omapip placeBottomLeft
omarchy-shell io.github.roddygithub.omapip placeBottomRight

# Cycle display mode
omarchy-shell io.github.roddygithub.omapip cycleDisplayMode
```

## Known Limitations

- Multi-monitor behavior has not yet received full validation
- Mixed-DPI behavior has not yet received full validation

## Compatibility & Status

| Item | Status |
|------|--------|
| Current release | v0.1.2 |
| Tests | 136 automated Node tests (86 display/behavior + 15 Phase A contract + 35 picker keyboard) plus Qt JavaScript-engine and QML key-delivery tests |
| GitHub Actions CI | Enabled (manifest + display + Phase A contract + Phase C picker keyboard + QML logic tests) |
| Marketplace | [Listed and verified with the current marketplace preview](https://omarchyplugins.com/plugin.html?id=io.github.roddygithub.omapip) in the Omarchy Plugin Marketplace |

## Project Structure

```
BarWidget.qml       # Bar widget entry point (Ui.BarWidget + IPC)
Panel.qml           # Picker + viewer logic (FloatingWindow, ScreencopyView)
PanelLogic.js       # Pure logic shared by QML and automated tests
manifest.json       # Omarchy plugin manifest
tests/
  test_display.js   # 86 display/geometry tests
  test_phase_a.js   # 15 Phase A contract tests
  test_phase_c.js   # 35 picker keyboard contract tests
  qml/              # Qt JavaScript-engine and key-delivery tests for shared logic
docs/
  README.md         # Current vs historical documentation map
  *.md              # Research and validation archive
SECURITY.md         # Security policy and reporting
LICENSE             # MIT
```

## Development

```bash
# Run automated Node tests
node tests/test_display.js
node tests/test_phase_a.js
node tests/test_phase_c.js

# Run shared JavaScript-module smoke tests through Qt (Qt required)
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input tests/qml

# Validate plugin manifest (on Omarchy)
omarchy plugin validate .
```

## Contributing

1. Fork and create a feature branch
2. Make focused changes with clear commit messages
3. Ensure the three Node suites (86/86, 15/15 and 35/35) and the Qt tests pass
4. Run `omarchy plugin validate .` locally if on Omarchy
5. Open a PR against `main`

No heavy framework, no boilerplate — small, reviewable diffs preferred.

## Issues

- **Bug reports**: Include Omarchy version, Hyprland version, Quickshell version, steps to reproduce, expected vs actual behavior, logs, and whether multi-monitor is in use
- **Feature requests**: Describe the problem, proposed behavior, and any alternatives considered

Issue templates are available in `.github/ISSUE_TEMPLATE/`.

## License

MIT — see [LICENSE](LICENSE).

---

*OmaPiP is a native Omarchy/Quickshell plugin. It is not affiliated with the Hyprland or Omarchy projects beyond using their public APIs.*
