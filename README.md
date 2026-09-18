# OmaPiP

OmaPiP mirrors one selected Wayland window in a floating `ScreencopyView`
inside `omarchy-shell`. It uses no helper, daemon, portal, or administrator privileges.

**External dependencies:** none beyond the standard Omarchy / Quickshell /
Hyprland environment. OmaPiP does not persist window titles, app IDs, selected
pixels, captures, credentials, or other window content to disk.

## Install and open

```bash
omarchy plugin add https://github.com/Roddygithub/OmaPiP.git --enable
```

The **** OmaPiP icon appears in the right bar section. Click it to open the
source picker, then select a window. To move the widget using Omarchy's normal
bar configuration:

```bash
omarchy bar move io.github.roddygithub.omapip --section right
```

The selected Hyprland address is retained only while the shell is running and
is never replaced implicitly. The CLI remains available as a secondary path:

```bash
omarchy-shell shell summon io.github.roddygithub.omapip
```

## Viewer controls

- **Left click + drag** moves the viewer freely; it is the normal way to position it.
- Drag any edge or corner to resize freely; Hyprland supplies the directional cursor.
- **Fill/Fit/Stretch** cycles the display mode (Fill = crop to cover, Fit = letterbox, Stretch = fill/distort).
- **Choose** reopens the source picker while capture continues.
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
