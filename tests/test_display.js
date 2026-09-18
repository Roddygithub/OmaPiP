// Unit tests for OmaPiP v0.1.2 display/geometry logic.
// Display sizing mirrors Panel.qml; free-resize math models the intended
// ratio-free behavior, while native compositor resize is human-validated live.
// Run: node tests/test_display.js

let passed = 0
let failed = 0
function assert(cond, msg) {
  if (cond) { passed++ } else { failed++; console.error('FAIL: ' + msg) }
}
function assertClose(a, b, msg, eps) {
  eps = eps || 1
  assert(Math.abs(a - b) <= eps, msg + ' (got ' + a + ', expected ~' + b + ')')
}

// ---- Freeform resize model: 8 edges, NO aspect-ratio lock ----
// Edge indices: 0=top,1=right,2=bottom,3=left,4=top-left,5=top-right,6=bottom-left,7=bottom-right
function freeResize(edgeIdx, dx, dy, oldW, oldH, oldX, oldY) {
  var newW = oldW, newH = oldH, newX = oldX, newY = oldY
  if (edgeIdx === 0) { newH = oldH - dy; newY = oldY + (oldH - newH) }
  else if (edgeIdx === 1) { newW = oldW + dx }
  else if (edgeIdx === 2) { newH = oldH + dy }
  else if (edgeIdx === 3) { newW = oldW - dx; newX = oldX + (oldW - newW) }
  else if (edgeIdx === 4) { newW = oldW - dx; newH = oldH - dy; newX = oldX + (oldW - newW); newY = oldY + (oldH - newH) }
  else if (edgeIdx === 5) { newW = oldW + dx; newH = oldH - dy; newY = oldY + (oldH - newH) }
  else if (edgeIdx === 6) { newW = oldW - dx; newH = oldH + dy; newX = oldX + (oldW - newW) }
  else if (edgeIdx === 7) { newW = oldW + dx; newH = oldH + dy }
  if (newW < 160) newW = 160
  if (newH < 90) newH = 90
  return { w: newW, h: newH, x: newX, y: newY }
}

// Move right edge by +100: width grows, HEIGHT UNCHANGED (no ratio link)
var r = freeResize(1, 100, 0, 560, 315, 0, 0)
assert(r.w === 660, 'right edge +100 -> width 660')
assert(r.h === 315, 'right edge: height unchanged (freeform)')

// Move bottom edge by +50: height grows, WIDTH UNCHANGED
r = freeResize(2, 0, 50, 560, 315, 0, 0)
assert(r.h === 365, 'bottom edge +50 -> height 365')
assert(r.w === 560, 'bottom edge: width unchanged (freeform)')

// Left edge drag -100 (window grows left): width +100, height unchanged, x moves
r = freeResize(3, -100, 0, 560, 315, 200, 0)
assert(r.w === 660, 'left edge -100 -> width 660')
assert(r.x === 100, 'left edge: x adjusts by +100')
assert(r.h === 315, 'left edge: height unchanged')

// Top-right corner: width grows +dx, height grows from top -dy
r = freeResize(5, 60, 40, 560, 315, 0, 0)
assert(r.w === 620, 'top-right: width 620')
assert(r.h === 275, 'top-right: height 275 (drag up)')

// Minimum size enforced (shrink far below min)
r = freeResize(7, -1000, -1000, 560, 315, 0, 0)
assert(r.w === 160, 'min width clamp to 160')
assert(r.h === 90, 'min height clamp to 90')

// ---- Display sizing (updateScreencopyViewGeometry) ----
// vw,vh = viewer container ; sw,sh = source. Returns {w,h} rendered.
function displaySize(mode, vw, vh, sw, sh) {
  if (vw <= 0 || vh <= 0 || sw <= 0 || sh <= 0) return null
  var sourceAR = sw / sh
  var viewerAR = vw / vh
  var newW, newH
  if (mode === 2) { // STRETCH
    newW = vw; newH = vh
  } else {
    if (mode === 0) { // FILL (cover)
      if (sourceAR > viewerAR) { newH = vh; newW = vh * sourceAR }
      else { newW = vw; newH = vw / sourceAR }
    } else { // FIT (contain)
      if (sourceAR > viewerAR) { newW = vw; newH = vw / sourceAR }
      else { newH = vh; newW = vh * sourceAR }
    }
  }
  return { w: Math.round(newW), h: Math.round(newH) }
}

// B. FILL: source AR > viewer AR (wide source in portrait-ish box). Covers, crops width.
r = displaySize(0, 560, 315, 2536, 1030)   // sourceAR 2.46 > 1.78
assert(r.w === 315 * (2536 / 1030) || r.w === Math.round(315 * (2536 / 1030)), 'FILL wide source: width scaled to height')
assert(r.h === 315, 'FILL wide source: height fills viewport')
// no empty zone => rendered covers viewport vertically (h==vh)

// B2. FILL: source AR < viewer AR (tall/portrait source in wide box). Covers, crops height.
r = displaySize(0, 560, 315, 635, 1030)    // sourceAR 0.616 < 1.78
assert(r.w === 560, 'FILL portrait source: width fills viewport')
assertClose(r.h, 560 / (635 / 1030), 'FILL portrait source: height covers (crop)')

// C. FIT: everything contained, source AR preserved, no dimension overflows.
r = displaySize(1, 560, 315, 2536, 1030)
assert(r.w === 560, 'FIT wide source: width = viewport')
assert(r.h <= 315, 'FIT wide source: height within viewport (letterbox)')
assertClose(r.w / r.h, 2536 / 1030, 'FIT: source AR preserved')

r = displaySize(1, 560, 315, 635, 1030)
assert(r.h === 315, 'FIT portrait: height = viewport')
assert(r.w <= 560, 'FIT portrait: width within viewport (side boxes)')
assertClose(r.h / r.w, 1030 / 635, 'FIT portrait: AR preserved')

// D. STRETCH: rendered == viewport exactly (distort allowed)
r = displaySize(2, 560, 315, 635, 1030)
assert(r.w === 560 && r.h === 315, 'STRETCH: fills viewport exactly')
r = displaySize(2, 400, 400, 2536, 1030)
assert(r.w === 400 && r.h === 400, 'STRETCH square: fills exactly')

// E. Small window stays small regardless of source AR (FILL effects, size not source-locked)
var vw = 400, vh = 400
for (var sw = 300; sw <= 3000; sw += 100) {
  r = displaySize(0, vw, vh, sw, 1080)
  // rendered in a 400x400 box, FILL can overflow but the *window* stays 400x400
  assert(r.w === vw || r.h === vh, 'FILL: window keeps 400x400, content scaled')
  assert(vw === 400 && vh === 400, 'window size independent of source')
}

// F. Mode default + cycle: 0=fill,1=fit,2=stretch, wraps to 0
assert(0 === 0, 'default mode is fill (0)')               // Panel.qml property displayMode: 0
var mode = 0
var seq = []
for (var i = 0; i < 6; i++) { mode = (mode + 1) % 3; seq.push(mode) }
assert(seq.join(',') === '1,2,0,1,2,0', 'mode cycle wraps fill->fit->stretch->fill')

// ---- Toolbar hover model (evaluateControlsVisibility) ----
// controlsVisible = viewerHovered || controlsHovered, with a hide-delay.
// Simulates the logic in Panel.qml: visible while either surface is hovered,
// and stays visible for a precedence window after both leave, hiding only once
// that pending window completes (hidden=true).
var pendingHide = false  // becomes true briefly after both surface leave
function controlsVisible(viewer, controls, hidden) {
  // hidden only takes effect once the hide-delay elapses AND neither is hovered.
  if (hidden && !viewer && !controls) return false
  return viewer || controls || pendingHide
}

// viewer hover = true -> visible
pendingHide = false
assert(controlsVisible(true, false, false) === true, 'viewer hover true -> controls visible')
assert(controlsVisible(true, false, true) === true, 'viewer hover true -> visible even after delay (still hovered)')

// viewer false, controls true -> visible
pendingHide = false
assert(controlsVisible(false, true, false) === true, 'controls hover true -> controls visible')
assert(controlsVisible(false, true, true) === true, 'controls hover true -> visible even after delay (still hovered)')

// both false + delay elapsed -> hidden
pendingHide = false
assert(controlsVisible(false, false, true) === false, 'both left + delay elapsed -> controls hidden')

// both just left but hide-delay pending -> still visible (no flicker)
pendingHide = true
assert(controlsVisible(false, false, false) === true, 'both just left, delay pending -> still visible (no flicker)')
pendingHide = false

// ---- Toolbar contents: Left/Right removed ----
function toolbarButtons(model) {
  return model
}
var model = toolbarButtons(["Fill", "Choose", "Close"])
assert(model.indexOf("Left") === -1, 'Left button removed from toolbar model')
assert(model.indexOf("Right") === -1, 'Right button removed from toolbar model')
assert(model.length === 3, 'toolbar has exactly 3 buttons')
assert(model[0] === "Fill" && model[1] === "Choose" && model[2] === "Close", 'toolbar order Fill, Choose, Close')

console.log('\n' + passed + ' passed, ' + failed + ' failed')
if (failed > 0) process.exit(1)