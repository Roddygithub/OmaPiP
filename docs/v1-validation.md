# Historical: OmaPiP V1 production validation

> Historical snapshot — this records an earlier implementation state and is not current release validation.


- **Version:** 0.1.0
- **Environment:** Omarchy shell / Quickshell 0.3.1 / Hyprland 0.56.2
- **Commit tested:** `0e1bcb3` (hardening branch)
- **Validation date:** 2026-09-16

## Technical checks

| Check | Result |
|---|---|
| `omarchy plugin validate .` | PASS |
| QML lint (`/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell -I /usr/lib/qt6/qml Panel.qml`) | PASS |
| CI manifest/whitespace job | PASS on prior merged baseline; final hardening job pending |
| Fresh install and shell load | PASS |
| Source enumeration and live `ScreencopyView` capture | PASS |
| Stable address destruction state | PASS: `resolvedAddress=""`, `sourceUnavailable=true` |
| Explicit reselection restores capture | PASS |
| Own picker/viewer surfaces excluded | PASS |
| Float, pin, raise, resize and placement dispatch | PASS |
| Bottom-left and bottom-right placement | PASS |
| Disable removes the live viewer | PASS |
| Remove leaves no plugin directory/configuration | PASS |

## Human checks

The user tested the production viewer and reported PASS for:

- left-click drag without `Super`;
- all eight resize directions and cursor feedback;
- Choose, Left, Right and Close controls;
- unavailable-source message interaction after the hit-target fix.

## Security review

PASS. The plugin uses scoped native Wayland move/resize requests for its own
`FloatingWindow`. Hyprland dispatches target the controlled OmaPiP viewer
address. No global mouse binding, persistent resize setting, privileged helper,
sudo operation, `/usr/share/omarchy` modification, or external daemon is used.

## Installation and removal

The tested path was install from the repository, enable, summon, select, capture,
source destruction, explicit reselection, placement, disable, and remove. The
final removal check reported no residual plugin directory.

## Accepted limitations

- `LIVE_GEOMETRIC_ASPECT_LOCK: NOT_SUPPORTED_V1`
- `MULTI_MONITOR_VALIDATION: DEFERRED`
- `MIXED_DPI_VALIDATION: DEFERRED`

## Release gate

`V1_PRODUCTION_PARITY_COMPLETE: YES`

`RELEASE_READY: YES`

The final human validation confirmed cross-workspace visibility, z-order above
normal windows, and the Close control. No tag, GitHub Release, or marketplace
submission has been made.
