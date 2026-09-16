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
  readonly property string viewerTitle: "OmaPiP Viewer — io.github.roddygithub.omapip"
  readonly property string pickerTitle: "OmaPiP Picker — io.github.roddygithub.omapip"
  readonly property bool sourceUnavailable: selectedAddress !== "" && resolvedToplevel === null

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
      root.viewerConfigured = false
      root.viewerVisible = true
      return "selected"
    }
    return "address-not-found"
  }

  function sources() {
    return JSON.stringify(root.sourceEntries.map(function(t) {
      return {
        address: t.address,
        title: t.title,
        appId: t.appId
      }
    }))
  }

  function status() {
    return JSON.stringify({
      selectedAddress: root.selectedAddress,
      resolvedAddress: root.resolvedToplevel ? root.resolvedToplevel.address : "",
      sourceUnavailable: root.sourceUnavailable,
      pickerVisible: root.pickerVisible,
      viewerVisible: root.viewerVisible,
      viewerConfigured: root.viewerConfigured,
      hasContent: viewer.hasContent,
      sourceSize: viewer.sourceSize.width + "x" + viewer.sourceSize.height
    })
  }

  function viewerAddress() {
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++)
      if (list[i].title === root.viewerTitle && root.validAddress(list[i].address)) return list[i].address
    return ""
  }

  function configureViewer() {
    var address = viewerAddress()
    if (address === "") return
    if (!root.validAddress(address)) return
    var selector = "address:0x" + address
    var monitor = Hyprland.focusedMonitor
    var width = 640
    var height = 360
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
    implicitWidth: 640
    implicitHeight: 360
    minimumSize: Qt.size(160, 90)

    Rectangle {
      anchors.fill: parent
      color: "#000000"
    }

    ScreencopyView {
      id: viewer
      anchors.centerIn: parent
      width: sourceSize.width > 0
        ? Math.min(parent.width, parent.height * sourceSize.width / sourceSize.height)
        : parent.width
      height: sourceSize.width > 0
        ? Math.min(parent.height, parent.width * sourceSize.height / sourceSize.width)
        : parent.height
      captureSource: root.resolvedToplevel ? root.resolvedToplevel.wayland : null
      live: true
      paintCursor: false
    }

    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: Math.max(0, (parent.height - viewer.height) / 2)
      z: 1.5
      color: "#000000"
    }
    Rectangle {
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: Math.max(0, (parent.height - viewer.height) / 2)
      z: 1.5
      color: "#000000"
    }

    MouseArea {
      anchors.fill: parent
      z: 1
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onPressed: function(event) {
        if (event.button === Qt.RightButton) root.chooseAnother()
        else viewerWindow.startSystemMove()
      }
    }

    // Native Wayland resize requests are scoped to this surface and preserve
    // Hyprland's directional cursor and border behavior.
    MouseArea { x: 0; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: true; cursorShape: Qt.SizeHorCursor; onPressed: viewerWindow.startSystemResize(Qt.LeftEdge) }
    MouseArea { x: parent.width - 10; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: true; cursorShape: Qt.SizeHorCursor; onPressed: viewerWindow.startSystemResize(Qt.RightEdge) }
    MouseArea { x: 12; y: 0; width: parent.width - 24; height: 10; z: 2; hoverEnabled: true; cursorShape: Qt.SizeVerCursor; onPressed: viewerWindow.startSystemResize(Qt.TopEdge) }
    MouseArea { x: 12; y: parent.height - 10; width: parent.width - 24; height: 10; z: 2; hoverEnabled: true; cursorShape: Qt.SizeVerCursor; onPressed: viewerWindow.startSystemResize(Qt.BottomEdge) }
    MouseArea { x: 0; y: 0; width: 12; height: 12; z: 3; hoverEnabled: true; cursorShape: Qt.SizeFDiagCursor; onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.LeftEdge) }
    MouseArea { x: parent.width - 12; y: 0; width: 12; height: 12; z: 3; hoverEnabled: true; cursorShape: Qt.SizeBDiagCursor; onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.RightEdge) }
    MouseArea { x: 0; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: true; cursorShape: Qt.SizeBDiagCursor; onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.LeftEdge) }
    MouseArea { x: parent.width - 12; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: true; cursorShape: Qt.SizeFDiagCursor; onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge) }

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
      Row {
        id: controlsRow
        anchors.centerIn: parent
        spacing: 4
        Repeater {
          model: ["Choose", "Left", "Right", "Close"]
          delegate: Rectangle {
            id: controlDelegate
            required property string modelData
            width: label.implicitWidth + 12
            height: 20
            radius: 3
            color: buttonMouse.containsMouse ? "#555555" : "#333333"
            Text { id: label; anchors.centerIn: parent; text: controlDelegate.modelData; color: "#ffffff"; font.pixelSize: 11 }
            MouseArea {
              id: buttonMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                if (controlDelegate.modelData === "Choose") root.chooseAnother()
                else if (controlDelegate.modelData === "Left") root.placeBottomLeft()
                else if (controlDelegate.modelData === "Right") root.placeBottomRight()
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
      visible: root.sourceUnavailable || !viewer.hasContent
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
