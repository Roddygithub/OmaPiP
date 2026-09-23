# Historical: OmaPiP ecosystem prior art audit

> Historical snapshot — research findings below are context, not the current product contract.

Date: 2026-09-16
Scope: prior art only. No OmaPiP V1 code was implemented.

## Method and source of truth

The primary source was the marketplace repository used to build the live registry:
[`omacom/omarchy-plugin-marketplace/registry.json`](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/registry.json), checked out locally at the audit time. The deployed catalog is generated from that registry (`site/assets/js/shared.js` loads `catalog.json`); it is not an independent source of plugin metadata.

The registry and generated catalog were searched for: `pip`, `picture-in-picture`, `floating`, `window`, `drag`, `resize`, `snap`, `pin`, `always-on-top`, `mirror`, `capture`, `screencopy`, `Wayland`, `Hyprland`, `multi-monitor`, and `scaling`. Exact target IDs and semantically relevant hits were then checked against their repositories, manifests, READMEs, licenses, and implementation files. No source code was copied.

The relevant registry entries are:

| Plugin | Registry repository / ID | Registry metadata | Audited source |
|---|---|---|---|
| PiP Handler | `SoftARV/omarchy-pip-handler` / `io.github.softarv.pip` | Desktop; `hyprland`, `media`, `bar`; service + bar-widget; manifest license field absent, repository MIT | commit `77d10006d93183aac1b8683bacd8a2d5ea40978b` |
| Floating Window Mode | `jwm3000/omarchy-windows` / `io.github.rawritude.floating-mode` | Desktop; registry tags only `system`; service + bar-widget; MIT | current checkout `e16b8a3fb4cfa243fd1e9af669e47c3d3e094f9e`, registry validation snapshot `46250af8579d2ec905dc069d14db71d22a70cbdb` |
| Screen Mirroring | `spaceXrace/omarchy-screen-mirroring` / `spacexrace.screen-mirroring` | Widgets; `bar`, `media`; bar-widget; manual setup; MIT | commit `8f27a9c14e0eb4d78734d6377ff6143280f731b9` |

`srburk/omarchy-pip` was not present in the registry at audit time. It was audited as external prior art at commit `959861e059df18e784c6c9250030874d3a8f9a85`; its manifest ID is `sburkhard.pip`, license MIT.

Marketplace verification is not a security review. The registry records `review-required` capabilities for the screen-mirroring plugin (`privilege`, `package-manager`) and for Floating Window Mode (`privilege`, `package-manager`, `installer`, `remote-build`), while PiP Handler records `installer`.

## Findings by plugin

### `io.github.softarv.pip` — PiP Handler

This is the closest functional equivalent for browser PiP, but not for arbitrary captured Wayland toplevels.

- **Identification:** a bash CLI reads `hyprctl clients -j`; configurable class/title matchers identify browser PiP, normalize bare versus `0x`-prefixed addresses, and choose deterministically among matches. The QML service only watches Hyprland events and delegates state to the CLI.
- **Floating, pin, raise:** Lua-form Hyprland dispatches apply `float`, `pin(action = "enable")`, and `alter_zorder(top)` in one `hyprctl --batch`. The project explicitly distinguishes pinning from raising.
- **Placement and work area:** `hyprctl monitors -j` supplies monitor coordinates, physical dimensions, scale, and reserved edges. `jq` converts to logical dimensions, subtracts reserved areas and margin, preserves aspect ratio, clamps the target size, and computes four corner coordinates.
- **Size:** configurable width fractions and presets; height is derived from the current source aspect ratio with a maximum-height clamp. A resize recomputes the corner position rather than retaining stale x/y.
- **Lifecycle:** open/title/resize/workspace events trigger refresh and application; address-scoped state is pruned after destruction. The source is browser PiP only, not `ScreencopyView`.
- **Multi-monitor/scaling:** geometry is selected from the monitor containing the PiP and has fixture coverage for dual monitors, offsets, fractional scale, rotation, and reserved areas. The README/spec deliberately do not optimize cross-monitor movement.
- **Complexity:** medium: one large bash CLI, `jq`, a small QML service/panel, persistent state, and user keybinds. Runtime dependencies are `bash`, `jq`, `hyprctl`, and Quickshell/Omarchy; installation is MIT.

Reusable pattern: keep source selection/capture in OmaPiP, but reuse the address normalization, monitor-local logical work-area calculation, batch ordering, explicit `pin` plus `alter_zorder`, and lifecycle reapplication ideas.

### `io.github.rawritude.floating-mode` — Floating Window Mode

This is the decisive prior art for mouse UX, but it does **not** solve it in QML.

- **Drag:** normal Hyprland compositor drag is used through the native titlebar (`hyprbars`) and `Super`+drag. The plugin's own native module observes compositor input and drag state to implement edge/corner snap previews and release handling.
- **Four edges and four corners:** `contrib/aero-snap/main.cpp` detects a cursor against the compositor-owned window border, maps the eight cases to Hyprland's `MBIND_RESIZE`/`Layout::CORNER_*`, and calls `g_layoutManager->beginDragTarget`. The top border is reserved for `hyprbars` dragging; bottom/left/right and three bottom corners are passed to resize. This is compositor input, not a QML MouseArea.
- **Cursors:** the native Hyprland resize operation supplies directional cursors. The Lua configuration enables `resize_on_border`, `extend_border_grab_area = 12`, `hover_icon_on_border`, and `resize_corner = 0`. The larger grab area is compositor-native and avoids an overlay surface.
- **Zones and geometry:** the native module uses Hyprland logical monitor boxes and `workspace->m_space->workArea(...)`, retaining reserved areas and handling monitor coordinates, gaps, min/max size, decoration/input extents, rotation/scale, and client-versus-outer rectangles.
- **Restoration:** native state stores the pre-snap rectangle per window. Dragging a snapped window away restores its previous size with an anchor under the cursor; keyboard snap keeps the original rectangle until explicit restore.
- **Floating and lifecycle:** Lua window rules float and initially size/center windows; the QML service owns setup/recovery state. `hyprctl`/Lua rules manage floating mode, while the native module handles compositor input and render previews.
- **What is not minimal:** the repository also includes a broad floating-mode product, `hyprbars` patches, installer and ABI management, per-workspace policy, transparency, snap previews, and state ledgers. These are not needed by one OmaPiP window.
- **Dependencies/licence:** MIT project. Basic runtime uses Omarchy, Hyprland, Quickshell, `hyprctl`, `jq`, `flock`, and `perl`; the complete UX requires a native Hyprland module compiled against the exact Hyprland ABI, the official `hyprbars` plugin plus local patches, a compiler toolchain, `hyprpm`, and a narrowly scoped `sudo` installer.

Important boundary: `hyprbars` provides the titlebar drag surface and buttons; it does not implement the eight-way border resize. `aero-snap` is the native Hyprland plugin that intercepts pointer events, chooses the resize direction, starts the compositor drag controller, and renders previews. The Lua file provides configuration/rules/dispatch functions, not the low-level pointer implementation. The shell service and scripts provide setup and persistence, not pointer interaction.

Reusable pattern: for OmaPiP, first try Hyprland's existing native `resize_on_border` and a native titlebar or compositor drag. Do not import Floating Mode's mode manager, snap zones, previews, installer, or global rules. A custom native module becomes justified only if a borderless `FloatingWindow` cannot expose a usable compositor border/titlebar or if exact eight-way interception is required.

### `spacexrace.screen-mirroring` — Screen Mirroring

This is prior art for selection and portal lifecycle, not a replacement for OmaPiP capture.

- **Selection:** the widget starts a portal-backed screen/window selection through `doubletake`; the user chooses a screen or window in the desktop portal for each connection.
- **Transport:** the portal negotiates PipeWire capture, then `doubletake` streams it to a receiver. This is a remote streaming architecture, unlike OmaPiP's in-process `ScreencopyView` viewer.
- **Lifecycle and permissions:** QML controls state while a Python helper supervises `doubletake`, private runtime files, credentials, unexpected exit cleanup, and tagged UFW rules. It requires `xdg-desktop-portal`, `xdg-desktop-portal-hyprland`, PipeWire/GStreamer, `doubletake-git`, UFW, Polkit, and related packages. The repository is MIT; `doubletake` is a separate LGPL-3.0-or-later dependency.
- **UX conclusion:** a portal could improve initial source selection and permission consent if OmaPiP needs a user-approved native window picker. It does not provide a better final local mirror than the already passing `ScreencopyView` path, and it adds helper/process/dependency complexity.

Reusable pattern: consider a portal only for explicit initial selection/consent, behind a probe and without changing the proven capture path.

### `sburkhard.pip` — external PiP prior art

This small MIT service injects Lua after Hyprland loads and re-injects it after reload. It identifies browser PiP by tag/title, uses Hyprland Lua `float`, `pin`, `resize`, `move`, and `alter_zorder`, and stores corner/width-ratio state in a Lua file.

Its useful interaction pattern is deliberately small: the compositor performs the normal drag; a release-only mouse binding finds the nearest corner, updates the remembered ratio from the resulting width, and snaps the PiP back with `move`. It does not implement eight-way resize or cursor feedback. Its geometry handles reserved areas, monitor scale, monitor selection, aspect ratio, minimum dimensions, and four corners. It is browser-PiP-specific and uses a helper `inject.sh`; it does not use a portal or `ScreencopyView`.

Reusable pattern: release-only corner snap and ratio persistence are candidates if OmaPiP can rely on normal compositor drag. The helper/reinjection mechanism is not needed if an Omarchy service can own the Lua lifecycle directly.

## Blocker matrix

| OmaPiP blocker | Existing solution | Plugin | Technique | Complexity | Candidate for OmaPiP |
|---|---|---|---|---|---|
| left-drag move | Yes | Floating Mode; srburk PiP | `hyprbars`/Hyprland compositor drag; release hook only snaps | Low without snap preview; high with native module | Yes: native titlebar or compositor drag; probe first |
| 4-edge resize | Yes | Floating Mode | Hyprland border resize; native module explicitly starts `MBIND_RESIZE` | Low if standard border works; high if custom interception | Conditional; test `resize_on_border` before native code |
| 4-corner resize | Yes | Floating Mode | Same compositor border path, explicit corner enum | Low if standard border works; high otherwise | Conditional; probe |
| resize cursors | Yes | Floating Mode | Hyprland native directional cursor feedback | Low via compositor config | Yes, if border is compositor-owned and visible |
| always-above | Yes | PiP Handler; srburk PiP | explicit `pin` plus `alter_zorder(top)`; pin and raise are separate | Low | Yes; use idempotent pin action and raise |
| all-workspaces pin | Yes, demonstrated by prior art | PiP Handler; srburk PiP | Hyprland `pin`; live cross-workspace behavior must still be checked for OmaPiP | Low | Yes; retain a focused host probe |
| aspect ratio | Yes | PiP Handler; srburk PiP | derive height from source ratio; recompute geometry after resize | Low | Yes; pure geometry plus live resize probe |
| corner placement | Yes | PiP Handler; srburk PiP | monitor-local four-corner formulas | Low | Yes; reuse pattern, not code |
| work area | Yes | PiP Handler; Floating Mode | reserved edges/workspace work area, logical coordinates | Low/medium | Yes; make one OmaPiP geometry helper |
| multi-monitor geometry | Fixture/pattern yes; live UX not fully | PiP Handler; Floating Mode; srburk PiP | select monitor from window/cursor; account for offsets, scale and rotation | Medium | Yes for single-monitor-local placement; live environment remains deferred |
| fractional scaling | Fixture/pattern yes | PiP Handler; Floating Mode; srburk PiP | convert physical monitor dimensions to logical coordinates; preserve rounding | Medium | Yes in geometry probe; do not claim live support yet |
| source selection | Yes | Screen Mirroring | desktop portal screen/window picker | Medium/high due portal/PipeWire/helper permissions | Optional UX probe only; not capture architecture |

## Reconciliation with OmaPiP work

The prior host-probe results remain historical facts. This audit does not convert any OmaPiP `FAIL` into `PASS`, and it does not replace the already passing in-process capture path.

| Discovery | Impact classification | Reconciliation with existing work |
|---|---|---|
| Browser-PiP plugins match browser windows, not arbitrary toplevel captures | `CONFIRMS_EXISTING_DECISION` | Keep `Hyprland.toplevels` + `ScreencopyView`; do not fork browser-PiP matching. |
| PiP Handler separates address matching, geometry, dispatch, and QML | `IMPROVES_EXISTING_APPROACH` | Keep the proposed thin plugin boundary; move only geometry/placement policy into a small focused unit. |
| PiP Handler and srburk use explicit pin plus raise | `INVALIDATES_PREVIOUS_ASSUMPTION` | The report's unresolved above/pin items must be interpreted as unverified on OmaPiP, not as evidence that a helper or new capture path is needed. Use separate idempotent operations. |
| Reserved-area/logical-scale/aspect math is already exercised by prior art | `IMPROVES_EXISTING_APPROACH` | Reuse the algorithmic pattern, but still run OmaPiP-specific checks; do not copy implementation or claim live multi-monitor support. |
| Floating Mode's custom eight-way interaction is native Hyprland code | `REQUIRES_NEW_TARGETED_PROBE` | Test standard `resize_on_border` on OmaPiP before deciding whether `aero-snap`-style native code is required. |
| `hyprbars` is titlebar drag, not eight-way resize | `INVALIDATES_PREVIOUS_ASSUMPTION` | A future probe must test titlebar/compositor drag and border resize separately. Installing or patching `hyprbars` is not automatically the answer. |
| srburk's release-only snap does not implement resize/cursors | `REMOVES_NEED_FOR_PROBE` | Remove any plan to probe a custom continuous QML drag implementation; probe compositor drag plus release snapping instead. |
| Screen Mirroring portal is for PipeWire remote streaming | `CONFIRMS_EXISTING_DECISION` | Portal selection is optional UX, not a replacement for local `ScreencopyView`. |
| Prior art has fixtures but no equivalent OmaPiP mixed-monitor environment here | `NO_IMPACT` | Preserve `DEFERRED_ENVIRONMENT_LIMITATION`; fixture evidence cannot change the local environment result. |

### Decisions retained

- No V1 implementation until the feasibility gate is approved.
- Omarchy third-party plugin in the real `omarchy-shell`.
- `Hyprland.toplevels` identity and `ScreencopyView` capture.
- `FloatingWindow` as the viewer surface.
- No external helper currently required.
- Multi-monitor and mixed-DPI remain environment-deferred.

### Decisions changed or sharpened

- The open mouse UX question is now explicitly split into **standard compositor capability** versus **custom native interception**. The first target is Hyprland configuration (`resize_on_border`, border grab area, cursor feedback), not QML hit testing.
- `always-above` and all-workspaces pin remain live OmaPiP probes, but the implementation candidate is now explicit `pin` plus `alter_zorder(top)` rather than a vague “above” rule.
- Automatic corner placement should use monitor-local logical work-area math and be applied after the viewer is mapped; it should not be conflated with interactive drag.
- A portal is downgraded to an optional selection/consent experiment and must not enter the capture architecture without a concrete UX result.

### Probes removed or no longer useful

- A probe for a QML-only global move/resize implementation is unnecessary: Wayland client QML cannot reposition an independent toplevel globally without compositor cooperation.
- A probe that substitutes PipeWire/portal capture for the already passing `ScreencopyView` path is unnecessary.
- Generic browser-PiP title/class matching is unnecessary for OmaPiP's `HyprlandToplevel` source model.

These removals do not remove the required OmaPiP host probes below; they narrow them.

### Refined next probes

1. **Surface interaction baseline:** on one real OmaPiP `FloatingWindow`, enable only standard Hyprland border resize and test left/right/top/bottom plus four corners, recording cursor names, actual geometry, minimum size, and whether capture/input remains live.
2. **Move baseline:** test compositor/titlebar or `Super`+left-drag, then release; record whether the viewer moves continuously and whether source capture is unaffected.
3. **Placement/ratio:** map a viewer with a known source aspect, compute bottom-right and bottom-left from current reserved work area, then resize while checking whether ratio is preserved by the chosen policy.
4. **Stack/workspace:** use an independent fullscreen/normal-window visual test and switch workspaces; record `pin`, visibility, and z-order separately.
5. **Only if 1 fails:** design one native Hyprland feasibility probe for the smallest required border interception. Do not build or import the Floating Mode module.

## Architecture check

1. **Existing equivalent:** **No.** PiP Handler and srburk PiP are browser-PiP managers. OmaPiP mirrors arbitrary `HyprlandToplevel` sources with `ScreencopyView`; no audited plugin combines that source model with the requested UX.
2. **Fork/extend:** **No.** Forking either PiP implementation would import browser matching, bash/`jq` or Lua state, and lifecycle assumptions unnecessarily. Floating Mode is useful as a pattern reference, not a sensible fork: it is a global floating-mode product whose native module and installer are much larger than one window.
3. **Already solved by patterns:** corner placement, reserved work-area math, logical scale conversion, aspect-preserving sizing, address matching, explicit pin/raise, lifecycle reapplication, normal compositor dragging, and native directional resize feedback.
4. **New probes still needed:** a real OmaPiP `FloatingWindow` with `resize_on_border` and visible border; left drag/release; all eight resize directions and cursors; whether the surface's input/decorations interfere; aspect-preserving live resize policy; above/fullscreen and cross-workspace visibility; automatic corner placement against current reserved areas. Multi-monitor and mixed-DPI remain environment-deferred.
5. **Can all UX work without a custom Hyprland native component?** **Possibly, and this is the minimal path to test.** QML cannot move or resize a toplevel globally by itself: Wayland clients request compositor operations. However, Hyprland already owns normal move/resize and cursor feedback through its border/titlebar interaction, and Lua/IPC can handle initial placement and release snapping. A custom native module is required only if standard Hyprland border interaction is unavailable/insufficient for the particular `FloatingWindow` surface, or if OmaPiP insists on custom border hit zones and compositor-level cursor/drag interception. Floating Mode demonstrates that such interception is real, but not that it is necessary for OmaPiP.
6. **Capture path:** **Yes, keep `ScreencopyView` as the primary path.** The portal is optional for selection consent only; Screen Mirroring's PipeWire/helper architecture solves a different remote-streaming problem.
7. **Smallest realistic V1 design:** one Omarchy `panel`/service plugin with `FloatingWindow` + `ScreencopyView` + `Hyprland.toplevels`; source identity by toplevel/address; a small QML/JS geometry function for monitor work area, ratio and corners; Lua/Hyprland dispatch for float, pin, raise, initial resize and move; standard Hyprland `resize_on_border`/cursor behavior and either a native titlebar or compositor drag. Add a release-only corner snap only if the drag probe confirms it is useful. Do not add a helper, portal, custom native module, hyprbars patch, global floating mode, snap preview, or multi-monitor policy in V1.
8. **Previous decisions to retain:** the host-only Omarchy plugin boundary, in-process `ScreencopyView` capture, `FloatingWindow`, no helper, and deferred multi-monitor/mixed-DPI status remain correct.
9. **Previous decisions to modify:** replace the broad “mouse UX blocker” with the two-stage standard-compositor-then-native decision; treat pin and raise as separate operations; remove QML-only drag and portal-capture probes.

## Audit conclusion

This audit changes the confidence boundary, not the capture architecture. The prior art proves that the remaining UX is compositor-owned and achievable, but it does not remove the need for OmaPiP-specific host probes. In particular, do not mark the project ready: standard border resize must be observed on the actual OmaPiP surface before deciding whether a native Hyprland component is needed.

`READY_TO_IMPLEMENT: NO`
