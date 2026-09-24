.pragma library

function normalizeAddress(value) {
  var address = String(value || "").trim()
  if (/^0x/i.test(address)) address = address.slice(2)
  if (!/^[0-9a-fA-F]{1,16}$/.test(address)) return ""
  return address.toLowerCase()
}

function isCapturableSource(toplevel, viewerTitle, pickerTitle) {
  if (!toplevel || !toplevel.wayland) return false
  if (toplevel.title === viewerTitle || toplevel.title === pickerTitle) return false
  return normalizeAddress(toplevel.address) !== ""
}

function indexForAddress(entries, address) {
  var wanted = normalizeAddress(address)
  if (wanted === "" || !entries) return -1
  for (var i = 0; i < entries.length; i++) {
    var entry = entries[i]
    if (entry && normalizeAddress(entry.address) === wanted) return i
  }
  return -1
}

function boundedNumber(value, fallback, minimum, maximum) {
  var number = Number(value)
  if (!isFinite(number)) return fallback
  return Math.round(Math.max(minimum, Math.min(maximum, number)))
}

function boundedIndex(current, count) {
  if (count <= 0) return -1
  var index = Number(current)
  if (!isFinite(index)) return 0
  return Math.max(0, Math.min(count - 1, Math.round(index)))
}

// Keyboard selection is tracked by address, so list churn (sources appearing
// or disappearing) re-resolves the same window instead of drifting with the
// slot. Falls back to the clamped current index when the anchor is gone.
function repairedIndex(current, anchorAddress, entries) {
  var count = entries ? entries.length : 0
  if (count <= 0) return -1
  var index = indexForAddress(entries, anchorAddress)
  if (index >= 0) return index
  return boundedIndex(current, count)
}

function displaySize(mode, viewerWidth, viewerHeight, sourceWidth, sourceHeight) {
  if (viewerWidth <= 0 || viewerHeight <= 0 || sourceWidth <= 0 || sourceHeight <= 0) return null
  var sourceAR = sourceWidth / sourceHeight
  var viewerAR = viewerWidth / viewerHeight
  var width, height
  if (mode === 2) {
    width = viewerWidth
    height = viewerHeight
  } else if (mode === 0) {
    if (sourceAR > viewerAR) {
      height = viewerHeight
      width = viewerHeight * sourceAR
    } else {
      width = viewerWidth
      height = viewerWidth / sourceAR
    }
  } else {
    if (sourceAR > viewerAR) {
      width = viewerWidth
      height = viewerWidth / sourceAR
    } else {
      height = viewerHeight
      width = viewerHeight * sourceAR
    }
  }
  return { w: Math.round(width), h: Math.round(height) }
}

function viewerConfigAfterSelect(viewerVisible, configured, attempts) {
  if (!viewerVisible) return { configured: false, attempts: 0 }
  return { configured: configured, attempts: attempts }
}

function initialViewerSize(monitorWidth, monitorHeight) {
  var mw = boundedNumber(monitorWidth, 1920, 160, 10000)
  var mh = boundedNumber(monitorHeight, 1080, 90, 10000)
  var width = Math.min(560, Math.round(mw * 0.35))
  var height = Math.min(315, Math.round(mh * 0.35))
  if (width < 240) width = 240
  if (height < 135) height = 135
  return { w: width, h: height }
}
