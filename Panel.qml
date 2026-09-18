pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
  id: root

  property string selectedAddress: ""
  property var resolvedToplevel: null
  property var sourceEntries: []
  property bool pickerVisible: false
  property bool viewerVisible: false
  property bool viewerConfigured: false
  property bool viewerHovered: false
  property bool controlsHovered: false
  property bool controlsVisible: false
  readonly property int controlsHideDelay: 280
  property int displayMode: 0  // 0 = Fill, 1 = Fit, 2 = Stretch
  readonly property string viewerTitle: "OmaPiP Viewer — io.github.roddygithub.omapip"
  readonly property string pickerTitle: "OmaPiP Picker — io.github.roddygithub.omapip"
  readonly property bool sourceUnavailable: selectedAddress !== "" && resolvedToplevel === null
  readonly property int modeFill: 0
  readonly property int modeFit: 1
  readonly property int modeStretch: 2

  function boundedText(value, limit) {
    return String(value || "").slice(0, limit)
  }

  function validAddress(value) {
    return /^[0-9a-fA-F]{1,16}$/.test(String(value || ""))
  }

  function boundedNumber(value, fallback, minimum, maximum) {
    var number = Number(value)
    if (!Number.isFinite(number)) return fallback
    return Math.round(Math.max(minimum, Math.min(maximum, number)))
  }

  function refreshSource() {
    Hyprland.refreshToplevels()
    var list = Hyprland.toplevels.values
    var found = null
    var entries = []
    for (var i = 0; i < list.length; i++) {
      var toplevel = list[i]
      if (toplevel.title === root.viewerTitle || toplevel.title === root.pickerTitle) continue
      if (!root.validAddress(toplevel.address)) continue
      entries.push({
        address: toplevel.address,
        title: root.boundedText(toplevel.title, 160),
        appId: root.boundedText(toplevel.wayland ? toplevel.wayland.appId : "", 80)
      })
      if (toplevel.address === root.selectedAddress) found = toplevel
    }
    root.sourceEntries = entries
    root.resolvedToplevel = found
  }

  function open(payload) {
    root.refreshSource()
    var address = String(payload || "").slice(0, 32).trim()
    if (address !== "" && root.select(address) === "selected") return
    root.pickerVisible = true
  }

  function close() {
    root.pickerVisible = false
    root.viewerVisible = false
    root.viewerConfigured = false
  }

  function chooseAnother() {
    root.refreshSource()
    root.pickerVisible = true
  }

  function cycleDisplayMode() {
    root.displayMode = (root.displayMode + 1) % 3
    updateScreencopyViewGeometry()
  }

  function displayModeName() {
    if (root.displayMode === root.modeFill) return "Fill"
    if (root.displayMode === root.modeFit) return "Fit"
    return "Stretch"
  }

  // Hover model: keep the toolbar visible while the pointer is over the
  // content OR over the toolbar itself. It fades out only after the pointer
  // leaves BOTH, using a short delay to avoid flicker when crossing to buttons.
  function evaluateControlsVisibility() {
    if (root.viewerHovered || root.controlsHovered) {
      controlsHideTimer.stop()
      root.controlsVisible = true
    } else {
      controlsHideTimer.restart()
    }
  }

  onViewerHoveredChanged: root.evaluateControlsVisibility()
  onControlsHoveredChanged: root.evaluateControlsVisibility()

  function placeBottomRight() { placeAt(false) }
  function placeBottomLeft() { placeAt(true) }

  function placeAt(left) {
    var address = viewerAddress()
    var monitor = Hyprland.focusedMonitor
    if (!root.validAddress(address) || !monitor) return
    var reserved = monitor.lastIpcObject && monitor.lastIpcObject.reserved || [0, 0, 0, 0]
    var leftReserved = root.boundedNumber(reserved[0], 0, 0, 10000)
    var rightReserved = root.boundedNumber(reserved[2], 0, 0, 10000)
    var bottomReserved = root.boundedNumber(reserved[3], 0, 0, 10000)
    var width = root.boundedNumber(viewerWindow.width, 640, 160, 4000)
    var height = root.boundedNumber(viewerWindow.height, 360, 90, 4000)
    var margin = 24
    var monitorX = root.boundedNumber(monitor.x, 0, -100000, 100000)
    var monitorY = root.boundedNumber(monitor.y, 0, -100000, 100000)
    var monitorWidth = root.boundedNumber(monitor.width, 1920, 160, 10000)
    var monitorHeight = root.boundedNumber(monitor.height, 1080, 90, 10000)
    var x = left ? monitorX + leftReserved + margin
      : monitorX + monitorWidth - rightReserved - width - margin
    var y = monitorY + monitorHeight - bottomReserved - height - margin
    var selector = "address:0x" + address
    var command = "dispatch hl.dsp.window.move({ x = " + x + ", y = " + y
      + ", window = \"" + selector + "\" }); dispatch hl.dsp.window.alter_zorder({ mode = \"top\", window = \""
      + selector + "\" })"
    Quickshell.execDetached(["hyprctl", "--batch", command])
  }

  function select(address) {
    var wanted = String(address || "").slice(0, 16)
    if (!root.validAddress(wanted)) return "invalid-address"
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++) {
      if (list[i].address !== wanted) continue
      root.selectedAddress = wanted
      root.resolvedToplevel = list[i]
      root.pickerVisible = false
      root.viewerVisible = true
      return "selected"
    }
    return "address-not-found"
  }

  function sources() {
    return JSON.stringify(root.sourceEntries.map(function(t) {
      return { address: t.address, title: t.title, appId: t.appId }
    }))
  }

  function status() {
    var ww = viewerWindow.width || 0
    var wh = viewerWindow.height || 0
    var sw = screencopyView.sourceSize ? screencopyView.sourceSize.width : 0
    var sh = screencopyView.sourceSize ? screencopyView.sourceSize.height : 0
    var rt = root.resolvedToplevel
    var waylandObj = rt ? rt.wayland : null
    var captureSourceObj = screencopyView.captureSource
    return JSON.stringify({
      selectedAddress: root.selectedAddress,
      resolvedAddress: rt ? rt.address : "",
      sourceUnavailable: root.sourceUnavailable,
      pickerVisible: root.pickerVisible,
      viewerVisible: root.viewerVisible,
      viewerConfigured: root.viewerConfigured,
      hasContent: screencopyView.hasContent,
      sourceSize: sw + "x" + sh,
      winSize: ww + "x" + wh,
      winAR: wh > 0 ? (ww / wh).toFixed(3) : "0",
      sourceAR: sh > 0 ? (sw / sh).toFixed(3) : "0",
      displayMode: root.displayModeName(),
      resolvedToplevelPresent: rt !== null,
      resolvedToplevelWaylandPresent: waylandObj !== null,
      waylandAppId: waylandObj ? waylandObj.appId : "",
      captureSourceMatches: captureSourceObj === waylandObj,
      captureSourcePresent: captureSourceObj !== null,
      viewSize: Math.round(screencopyView.width) + "x" + Math.round(screencopyView.height)
    })
  }

  function viewerAddress() {
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++)
      if (list[i].title === root.viewerTitle && root.validAddress(list[i].address)) return list[i].address
    return ""
  }

  function computeInitialSize() {
    var monitor = Hyprland.focusedMonitor
    if (!monitor) return { w: 560, h: 315 }
    var mw = root.boundedNumber(monitor.width, 1920, 160, 10000)
    var mh = root.boundedNumber(monitor.height, 1080, 90, 10000)
    var maxW = Math.round(mw * 0.35)
    var maxH = Math.round(mh * 0.35)
    var w = Math.min(560, maxW)
    var h = Math.min(315, maxH)
    if (w < 240) w = 240
    if (h < 135) h = 135
    return { w: w, h: h }
  }

  function configureViewer() {
    var address = viewerAddress()
    if (address === "") return
    if (!root.validAddress(address)) return
    var selector = "address:0x" + address
    var size = root.computeInitialSize()
    var width = size.w
    var height = size.h
    var monitor = Hyprland.focusedMonitor
    var reserved = monitor && monitor.lastIpcObject && monitor.lastIpcObject.reserved || [0, 0, 0, 0]
    var rightReserved = root.boundedNumber(reserved[2], 0, 0, 10000)
    var bottomReserved = root.boundedNumber(reserved[3], 0, 0, 10000)
    var monitorX = monitor ? root.boundedNumber(monitor.x, 0, -100000, 100000) : 0
    var monitorY = monitor ? root.boundedNumber(monitor.y, 0, -100000, 100000) : 0
    var monitorWidth = monitor ? root.boundedNumber(monitor.width, 1920, 160, 10000) : 1920
    var monitorHeight = monitor ? root.boundedNumber(monitor.height, 1080, 90, 10000) : 1080
    var x = monitorX + monitorWidth - rightReserved - width - 24
    var y = monitorY + monitorHeight - bottomReserved - height - 24
    var commands = [
      "dispatch hl.dsp.window.float({ action = \"enable\", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.pin({ action = \"enable\", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.alter_zorder({ mode = \"top\", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.resize({ x = " + width + ", y = " + height + ", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.move({ x = " + x + ", y = " + y + ", window = \"" + selector + "\" })"
    ]
    Quickshell.execDetached(["hyprctl", "--batch", commands.join("; ")])
    root.viewerConfigured = true
  }

  function updateScreencopyViewGeometry() {
    if (!screencopyView.sourceSize || screencopyView.sourceSize.width <= 0 || screencopyView.sourceSize.height <= 0) return
    var vw = viewerContainer.width
    var vh = viewerContainer.height
    var sw = screencopyView.sourceSize.width
    var sh = screencopyView.sourceSize.height
    if (vw <= 0 || vh <= 0) return

    var mode = root.displayMode
    var newW, newH

    if (mode === root.modeStretch) {
      newW = vw
      newH = vh
    } else {
      var sourceAR = sw / sh
      var viewerAR = vw / vh
      if (mode === root.modeFill) {
        // Cover: scale to cover entire viewer
        if (sourceAR > viewerAR) {
          // Source wider relative to viewer: fit height, crop width
          newH = vh
          newW = vh * sourceAR
        } else {
          // Source taller relative to viewer: fit width, crop height
          newW = vw
          newH = vw / sourceAR
        }
      } else { // MODE_FIT
        // Contain: fit entire source in viewer
        if (sourceAR > viewerAR) {
          // Source wider: fit width, letterbox height
          newW = vw
          newH = vw / sourceAR
        } else {
          // Source taller: fit height, letterbox width
          newH = vh
          newW = vh * sourceAR
        }
      }
    }

    screencopyView.width = Math.round(newW)
    screencopyView.height = Math.round(newH)
  }

  Connections {
    target: screencopyView
    function onSourceSizeChanged() {
      updateScreencopyViewGeometry()
    }
  }

  // Recompute Fill/Fit/Stretch when the PiP window is resized (native resize
  // changes viewerContainer freely, and the view size must follow).
  Connections {
    target: viewerContainer
    function onWidthChanged() { updateScreencopyViewGeometry() }
    function onHeightChanged() { updateScreencopyViewGeometry() }
  }

  Timer {
    id: controlsHideTimer
    interval: root.controlsHideDelay
    repeat: false
    onTriggered: root.controlsVisible = false
  }

  Timer {
    interval: 300
    running: root.viewerVisible && !root.viewerConfigured
    repeat: true
    onTriggered: root.configureViewer()
  }

  Timer {
    interval: 500
    running: root.pickerVisible || root.viewerVisible
    repeat: true
    onTriggered: root.refreshSource()
  }

  FloatingWindow {
    id: picker
    visible: root.pickerVisible
    title: root.pickerTitle
    implicitWidth: 420
    implicitHeight: 480
    minimumSize: Qt.size(300, 240)

    Rectangle {
      anchors.fill: parent
      color: "#151515"

      Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        Text {
          text: "Choose a window to mirror"
          color: "#ffffff"
          font.pixelSize: 18
        }

        Text {
          text: root.sourceEntries.length ? "Select a live Wayland window." : "No windows found."
          color: "#aaaaaa"
          font.pixelSize: 13
        }

        ListView {
          id: sourceList
          width: parent.width
          height: parent.height - y
          model: root.sourceEntries
          clip: true
          spacing: 6

          delegate: Rectangle {
            id: sourceDelegate
            required property var modelData
            width: sourceList.width
            height: 54
            radius: 5
            color: mouse.containsMouse ? "#3b3b3b" : "#252525"

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.right: parent.right
              anchors.rightMargin: 12
              anchors.top: parent.top
              anchors.topMargin: 8
              textFormat: Text.PlainText
              text: sourceDelegate.modelData.title || sourceDelegate.modelData.appId || sourceDelegate.modelData.address
              color: "#ffffff"
              elide: Text.ElideRight
              font.pixelSize: 14
            }
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              textFormat: Text.PlainText
              text: sourceDelegate.modelData.appId
              color: "#999999"
              font.pixelSize: 11
            }
            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.select(sourceDelegate.modelData.address)
            }
          }
        }
      }
    }
  }

  FloatingWindow {
    id: viewerWindow
    visible: root.viewerVisible
    title: root.viewerTitle
    color: "#000000"
    implicitWidth: 560
    implicitHeight: 315
    minimumSize: Qt.size(160, 90)

    Rectangle {
      id: viewerContainer
      anchors.fill: parent
      color: "#000000"
      clip: true

      ScreencopyView {
        id: screencopyView
        anchors.centerIn: parent
        width: 1
        height: 1
        captureSource: root.resolvedToplevel ? root.resolvedToplevel.wayland : null
        live: true
        paintCursor: false
      }
    }

    // Body interaction: hover source + move + right-click (Choose).
    MouseArea {
      anchors.fill: parent
      z: 1
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: root.viewerHovered = true
      onExited: root.viewerHovered = false
      onPressed: function(event) {
        if (event.button === Qt.RightButton) root.chooseAnother()
        else viewerWindow.startSystemMove()
      }
    }

    // Native freeform resize: the compositor handles the drag, so geometry
    // always tracks the mouse and never fights a ratio-lock. Cursors come
    // from a passive HoverHandler so the edges stay hover-transparent and
    // never fade the controls while approaching them.
    MouseArea { x: 0; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeHorCursor }
      onPressed: viewerWindow.startSystemResize(Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 10; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeHorCursor }
      onPressed: viewerWindow.startSystemResize(Qt.RightEdge)
    }
    MouseArea { x: 12; y: 0; width: parent.width - 24; height: 10; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeVerCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge)
    }
    MouseArea { x: 12; y: parent.height - 10; width: parent.width - 24; height: 10; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeVerCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge)
    }
    MouseArea { x: 0; y: 0; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeFDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 12; y: 0; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeBDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.RightEdge)
    }
    MouseArea { x: 0; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeBDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 12; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeFDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }

    Rectangle {
      id: controls
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: 8
      z: 4
      width: controlsRow.implicitWidth + 8
      height: 28
      color: "#cc151515"
      radius: 4
      opacity: root.controlsVisible ? 1.0 : 0.0
      visible: opacity > 0
      Behavior on opacity {
        NumberAnimation { duration: root.viewerHovered || root.controlsHovered ? 120 : 175 }
      }

      // Track hover over the toolbar itself so it stays visible while the
      // pointer is here, independently of the content area.
      HoverHandler {
        id: controlsHoverArea
        onHoveredChanged: root.controlsHovered = controlsHoverArea.hovered
      }

      Row {
        id: controlsRow
        anchors.centerIn: parent
        spacing: 4
        Repeater {
          model: ["Fill", "Choose", "Close"]
          delegate: Rectangle {
            id: controlDelegate
            required property string modelData
            width: label.implicitWidth + 12
            height: 20
            radius: 3
            // Passive HoverHandler drives the highlight; it does NOT steal
            // hover from the parent overlay, so the controls stay visible.
            color: hover.hovered ? "#555555" : "#333333"
            Text { id: label; anchors.centerIn: parent; text: controlDelegate.modelData === "Fill" ? root.displayModeName() : controlDelegate.modelData; color: "#ffffff"; font.pixelSize: 11 }
            HoverHandler { id: hover }
            MouseArea {
              id: buttonMouse
              anchors.fill: parent
              hoverEnabled: false
              onClicked: {
                if (controlDelegate.modelData === "Fill") root.cycleDisplayMode()
                else if (controlDelegate.modelData === "Choose") root.chooseAnother()
                else root.close()
              }
            }
          }
        }
      }
    }

    Rectangle {
      id: unavailableBox
      anchors.centerIn: parent
      z: 4
      visible: root.sourceUnavailable || !screencopyView.hasContent
      color: "#cc151515"
      radius: 4
      width: message.implicitWidth + 28
      height: message.implicitHeight + 18
      Text {
        id: message
        anchors.centerIn: parent
        text: root.sourceUnavailable ? "Source unavailable — Choose another window" : "Waiting for capture…"
        color: "#ffffff"
        font.pixelSize: 14
      }
      MouseArea {
        anchors.fill: parent
        z: 5
        enabled: root.sourceUnavailable
        acceptedButtons: Qt.LeftButton
        onClicked: root.chooseAnother()
      }
    }
  }
}