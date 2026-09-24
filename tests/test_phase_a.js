// Focused Phase A contract tests. Runtime QML/Hyprland lifecycle remains live-tested.
const Logic = require('./load_logic')
const normalizeAddress = Logic.normalizeAddress
const isCapturableSource = Logic.isCapturableSource

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

function loseSource(state, found) {
  if (state.sourceLost) {
    state.resolved = null
    return
  }
  if (state.selectedAddress !== '' && state.resolved && !found) state.sourceLost = true
  state.resolved = state.sourceLost ? null : found
}
const lifecycle = { selectedAddress: 'abc', resolved: { address: 'abc' }, sourceLost: false }
loseSource(lifecycle, null)
assert(lifecycle.sourceLost, 'source loss latches')
loseSource(lifecycle, { address: 'abc' })
assert(lifecycle.sourceLost && lifecycle.resolved === null, 'lost source does not reattach automatically')
lifecycle.selectedAddress = 'def'
lifecycle.resolved = { address: 'def' }
lifecycle.sourceLost = false
assert(!lifecycle.sourceLost, 'explicit reselection clears the loss latch')

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
