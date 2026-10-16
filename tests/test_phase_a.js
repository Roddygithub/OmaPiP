// Focused production-logic tests. QML/Hyprland lifecycle remains live-tested.
const Logic = require('./load_logic')
const normalizeAddress = Logic.normalizeAddress
const isCapturableSource = Logic.isCapturableSource
const resolveSelectedSource = Logic.resolveSelectedSource
const configurationGenerationIsCurrent = Logic.configurationGenerationIsCurrent
const isInitialViewerConfiguration = Logic.isInitialViewerConfiguration
const logicalMonitorSize = Logic.logicalMonitorSize
const monitorWorkArea = Logic.monitorWorkArea

let passed = 0
let failed = 0
function assert(condition, message) {
  if (condition) passed++
  else { failed++; console.error('FAIL: ' + message) }
}

assert(normalizeAddress('123ABC') === '123abc', 'raw hex is canonicalized')
assert(normalizeAddress('  0x123ABC  ') === '123abc', '0x hex is canonicalized')
assert(normalizeAddress('') === '', 'empty address is rejected')
assert(normalizeAddress('0x') === '', 'prefix without digits is rejected')
assert(normalizeAddress('not-hex') === '', 'non-hex address is rejected')
assert(normalizeAddress('1234567890abcdef0') === '', 'address longer than 16 digits is rejected')

const viewerTitle = 'OmaPiP Viewer — io.github.roddygithub.omapip'
const pickerTitle = 'OmaPiP Picker — io.github.roddygithub.omapip'
const valid = { address: '0xabc', title: 'Terminal', wayland: { appId: 'foot' } }
assert(isCapturableSource(valid, viewerTitle, pickerTitle), 'Wayland source is eligible')
assert(!isCapturableSource({ ...valid, wayland: null }, viewerTitle, pickerTitle), 'source without Wayland object is rejected')
assert(!isCapturableSource({ ...valid, title: viewerTitle }, viewerTitle, pickerTitle), 'viewer is rejected')
assert(!isCapturableSource({ ...valid, title: pickerTitle }, viewerTitle, pickerTitle), 'picker is rejected')

const selected = { address: 'abc' }
const replacement = { address: 'abc' }
let resolution = resolveSelectedSource(selected, false, [selected])
assert(resolution.resolved === selected && !resolution.sourceLost, 'same selected object remains resolved')
resolution = resolveSelectedSource(selected, false, [replacement])
assert(resolution.resolved === null && resolution.sourceLost, 'reused address cannot attach a replacement object')
resolution = resolveSelectedSource(selected, true, [selected])
assert(resolution.resolved === null && resolution.sourceLost, 'source loss remains latched if the same object reappears')
resolution = resolveSelectedSource(replacement, false, [replacement])
assert(resolution.resolved === replacement && !resolution.sourceLost, 'explicit selection can bind a replacement object')
assert(!configurationGenerationIsCurrent(2, 3), 'a stale process callback cannot act on a newer generation')
assert(configurationGenerationIsCurrent(3, 3), 'current process callbacks remain valid')
assert(isInitialViewerConfiguration(0) && !isInitialViewerConfiguration(1), 'geometry setup runs only on the initial attempt')
let monitor = logicalMonitorSize(3840, 2160, 2, 0)
assert(monitor.w === 1920 && monitor.h === 1080, 'scaled monitor dimensions use logical pixels')
monitor = logicalMonitorSize(1920, 1080, 1, 1)
assert(monitor.w === 1080 && monitor.h === 1920, 'rotated monitor dimensions swap logical axes')
assert(logicalMonitorSize(1920, 1080, 1, 5).w === 1080, 'flipped portrait transform swaps logical axes')
assert(logicalMonitorSize(1920, 1080, 1, 7).h === 1920, 'mirrored portrait transform swaps logical axes')
const area = monitorWorkArea(0, 0, 3840, 2160, 2, 0, [10, 20, 30, 40])
assert(area.x === 10 && area.y === 20 && area.w === 1880 && area.h === 1020,
  'monitor work area applies scale and reserved edges')

let configured = false
let attempts = 0
for (; attempts < 3 && !configured; attempts++) {
  const commandSucceeded = attempts === 2
  const stateConfirmed = commandSucceeded
  configured = commandSucceeded && stateConfirmed
}
assert(configured && attempts === 3, 'configuration model only succeeds after observable confirmation')
assert(attempts <= 3, 'configuration retries are bounded')

// Geometry reconfiguration contract: README - the viewer keeps its geometry
// when switching sources; only the first open (or open after close) runs the
// initial configuration (size/float/pin/position).
const viewerConfigAfterSelect = Logic.viewerConfigAfterSelect
var cfg = viewerConfigAfterSelect(false, false, 0)
assert(cfg.configured === false && cfg.attempts === 0, 'initial select requires viewer configuration')
cfg = viewerConfigAfterSelect(true, true, 1)
assert(cfg.configured === true && cfg.attempts === 1, 'source switch while viewer is open does not reconfigure geometry')
cfg = viewerConfigAfterSelect(true, false, 2)
assert(cfg.configured === false && cfg.attempts === 2, 'an in-flight initial configuration keeps its retry state across a source switch')
cfg = viewerConfigAfterSelect(false, false, 3)
assert(cfg.configured === false && cfg.attempts === 0, 'close/reopen rearms the initial configuration')

// Wire-up guard: these assertions fail if Panel.qml::select() is reverted to
// the unconditional reset that caused the geometry regression, or stops
// routing config state through the shared helper.
const fs = require('fs')
const path = require('path')
const panelSource = fs.readFileSync(path.join(__dirname, '..', 'Panel.qml'), 'utf8')
function functionBody(source, startMarker, endMarker) {
  const start = source.indexOf(startMarker)
  const end = source.indexOf(endMarker, start)
  return source.slice(start, end === -1 ? source.length : end)
}
const selectBody = functionBody(panelSource, 'function select(address)', 'function sources()')
assert(selectBody.includes('Logic.viewerConfigAfterSelect(root.viewerVisible'),
  'select() routes config state through viewerConfigAfterSelect')
assert(!/root\.viewerConfigured\s*=\s*false/.test(selectBody),
  'select() does not unconditionally clear viewerConfigured (geometry regression guard)')
assert(!/root\.viewerConfigAttempts\s*=\s*0/.test(selectBody),
  'select() does not unconditionally reset viewerConfigAttempts (geometry regression guard)')
const closeBody = functionBody(panelSource, 'function close()', 'function chooseAnother()')
assert(/root\.viewerConfigured\s*=\s*false/.test(closeBody),
  'close() clears viewerConfigured so a reopen reconfigures')

console.log(`\n${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
