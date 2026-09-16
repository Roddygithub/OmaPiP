# OmaPiP

OmaPiP mirrors one selected Wayland window in a floating `ScreencopyView`
inside `omarchy-shell`. It uses no helper, daemon, portal, or sudo.

## Install and open

```bash
omarchy plugin add https://github.com/Roddygithub/OmaPiP.git --enable
omarchy-shell shell summon io.github.roddygithub.omapip
```

Select a source in the picker. The selected Hyprland address is retained while
the shell is running and is never replaced implicitly.

## Viewer controls

- **Left click + drag** moves the viewer without `Super`.
- Drag any edge or corner to resize; Hyprland supplies the directional cursor.
- **Choose** reopens the source picker while capture continues.
- **Left** and **Right** place the viewer in the corresponding bottom corner.
- **Close** closes only OmaPiP, not the source window.
- If the source is destroyed, click **Choose another window** to reselect it.

The viewer is floating, pinned across workspaces, raised above normal windows,
and initially placed bottom-right inside the monitor's reserved work area.

## Inspect state

```bash
omarchy-shell shell call io.github.roddygithub.omapip status ''
```

## Disable or uninstall

```bash
omarchy plugin disable io.github.roddygithub.omapip
omarchy plugin remove io.github.roddygithub.omapip --yes
```

## V1 limitations

- `LIVE_GEOMETRIC_ASPECT_LOCK: NOT_SUPPORTED_V1`
- `MULTI_MONITOR_VALIDATION: DEFERRED`
- `MIXED_DPI_VALIDATION: DEFERRED`

The capture is aspect-fit and may show letterboxing while the viewer is resized.
