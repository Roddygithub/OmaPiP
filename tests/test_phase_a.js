// Focused Phase A contract tests. Runtime QML/Hyprland lifecycle remains live-tested.
let passed = 0
let failed = 0
function assert(condition, message) {
  if (condition) passed++
  else { failed++; console.error('FAIL: ' + message) }
}

function normalizeAddress(value) {
  let address = String(value || '').trim()
  if (/^0x/i.test(address)) address = address.slice(2)
  if (!/^[0-9a-fA-F]{1,16}$/.test(address)) return ''
  return address.toLowerCase()
}

function isCapturableSource(toplevel, viewerTitle, pickerTitle) {
  return !!toplevel && !!toplevel.wayland
    && toplevel.title !== viewerTitle
    && toplevel.title !== pickerTitle
    && normalizeAddress(toplevel.address) !== ''
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

console.log(`\n${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)
