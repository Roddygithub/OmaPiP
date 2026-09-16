# Disposable real-host probe

This is a **NON-PRODUCTION** probe. It is copied temporarily into
`~/.config/omarchy/plugins/io.github.roddygithub.omapip-probe/` and loaded by
the existing `omarchy-shell` only for feasibility experiments. It must not be
used as OmaPiP V1 code.

The probe exposes the host's Hyprland toplevel model through `shell call`,
selects a `HyprlandToplevel`, and feeds its `.wayland` handle to
`ScreencopyView`. Its temporary installation is intentionally removed after
each test session.
