// Phase D viewer identity / toolbar stacking / accessibility contract.
// Live behavior (float/pin on the real viewer, screen-reader output) stays
// human-validated; these tests pin the logic and the Panel.qml wiring.
const Logic = require('./load_logic')
const matchesViewer = Logic.matchesViewer

let passed = 0
let failed = 0
function assert(condition, message) {
  if (condition) passed++
  else { failed++; console.error('FAIL: ' + message) }
}

const viewerTitle = 'OmaPiP Viewer — io.github.roddygithub.omapip'
const appId = 'org.quickshell'
const viewer = { address: '0xabc', title: viewerTitle, wayland: { appId: 'org.quickshell' } }

assert(matchesViewer(viewer, viewerTitle, appId), 'viewer title + quickshell app id matches')
assert(matchesViewer({ ...viewer, address: '  0xABC  ' }, viewerTitle, appId), 'address is normalized before matching')
assert(!matchesViewer({ ...viewer, wayland: { appId: 'evil.app' } }, viewerTitle, appId),
  'same title with a foreign app id is rejected (title spoofing)')
assert(!matchesViewer({ ...viewer, title: 'Other Window' }, viewerTitle, appId),
  'foreign window with the quickshell app id is rejected')
assert(!matchesViewer({ ...viewer, wayland: null }, viewerTitle, appId), 'missing wayland object is rejected')
assert(!matchesViewer(null, viewerTitle, appId), 'null toplevel is rejected')
assert(!matchesViewer({ ...viewer, address: 'not-hex' }, viewerTitle, appId), 'invalid address is rejected')

// Wire-up guards: fail if Panel.qml reverts to title-only viewerAddress or
// drops the toolbar-above-box stacking / accessible names.
const fs = require('fs')
const path = require('path')
const panelSource = fs.readFileSync(path.join(__dirname, '..', 'Panel.qml'), 'utf8')
function functionBody(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker)
  const end = source.indexOf(endMarker, start + 1)
  return source.slice(start, end === -1 ? source.length : end)
}
const viewerAddrBody = functionBody(panelSource, 'function viewerAddress()', 'function computeInitialSize()')
assert(viewerAddrBody.includes('Logic.matchesViewer'), 'viewerAddress routes through matchesViewer')
assert(viewerAddrBody.includes('root.viewerAppId'), 'viewerAddress checks the quickshell app id')
assert(!viewerAddrBody.includes('list[i].title === root.viewerTitle && address'),
  'viewerAddress no longer trusts a bare title match')

const controlsBlock = functionBody(panelSource, 'id: controls', 'id: unavailableBox')
assert(controlsBlock.includes('z: 5'), 'toolbar stacks above the unavailable box (z: 5 > z: 4)')
assert(controlsBlock.includes('Accessible.role: Accessible.Button'), 'toolbar buttons expose a button role')
assert(controlsBlock.includes('Accessible.name:'), 'toolbar buttons expose accessible names')
assert(controlsBlock.includes('Display mode: '), 'mode button announces the current display mode')
assert(controlsBlock.includes('Choose another source'), 'choose button has an accessible name')
assert(controlsBlock.includes('Close picture-in-picture'), 'close button has an accessible name')
assert(controlsBlock.includes('activeFocusOnTab: true'), 'toolbar controls participate in Tab traversal')
assert(controlsBlock.includes('Keys.onPressed') && controlsBlock.includes('Qt.Key_Space'), 'focused controls activate with keyboard keys')
assert(controlsBlock.includes('Accessible.onPressAction'), 'toolbar controls expose accessibility press actions')
assert(controlsBlock.includes('border.width: activeFocus ? 2 : 0'), 'keyboard focus has a visible indicator')
assert(controlsBlock.includes('root.controlsFocused'), 'keyboard focus keeps the toolbar visible')

const pickerBlock = functionBody(panelSource, 'id: sourceList', 'id: viewerWindow')
assert(pickerBlock.includes('Accessible.role: Accessible.ListItem'), 'picker entries expose list-item semantics')
assert(pickerBlock.includes('Accessible.selected:'), 'picker exposes the selected item state')
assert(panelSource.includes('onClosed: root.dismissPicker()'), 'closing picker window clears picker state')
assert(panelSource.includes('Viewer setup failed — close and reopen to retry'), 'viewer setup failures have a user-facing recovery path')
assert(panelSource.includes('Capture did not start — choose another window or reopen'), 'capture startup failure does not wait indefinitely')

const boxBlock = functionBody(panelSource, 'id: unavailableBox', 'no-such-marker-end-of-file')
assert(boxBlock.includes('z: 4'), 'unavailable box keeps z: 4 (above body/resize, below toolbar)')
assert(boxBlock.includes('Accessible.role: Accessible.StaticText'), 'state message exposes a static text role')

assert(panelSource.includes('readonly property string viewerAppId: "org.quickshell"'),
  'Panel.qml declares the quickshell viewer app id')

// Source tracking and placement wiring. These guards pin Quickshell-only
// wiring that cannot execute outside the real shell (Hyprland.monitorFor and
// the toplevels model): re-placement must follow the viewer's own monitor
// with a focused fallback, and model events must sync without forcing a
// refresh (no re-entrancy into refreshToplevels).
const viewerMonitorBody = functionBody(panelSource, 'function viewerMonitor()', 'function placeAt(')
assert(viewerMonitorBody.includes('Hyprland.monitorFor(screen)'), 'placement resolves the monitor from the viewer screen')
assert(viewerMonitorBody.includes('Hyprland.focusedMonitor'), 'monitor resolution falls back to the focused monitor')
const placeBody = functionBody(panelSource, 'function placeAt(', 'function select(')
assert(placeBody.includes('root.viewerMonitor()'), 're-placement uses the viewer\'s own monitor')
const syncBody = functionBody(panelSource, 'function syncSources()', '// Explicit refresh')
assert(syncBody.includes('Hyprland.toplevels.values') && !syncBody.includes('refreshToplevels'),
  'event sync reads the live model without forcing an IPC refresh')
const refreshBody = functionBody(panelSource, 'function refreshSource()', 'function open(')
assert(refreshBody.includes('Hyprland.refreshToplevels()') && refreshBody.includes('root.syncSources()'),
  'explicit refresh forces a re-query then syncs')
const eventHook = functionBody(panelSource, 'target: Hyprland.toplevels', 'Timer {')
assert(eventHook.includes('function onValuesChanged()'), 'toplevel model changes are tracked event-driven')
assert(eventHook.includes('root.pickerVisible || root.viewerVisible'), 'event tracking only runs while a surface is visible')
assert(eventHook.includes('root.syncSources()') && !eventHook.includes('refreshSource()'),
  'model events sync state without re-entering the forced refresh')

console.log(`\n${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
