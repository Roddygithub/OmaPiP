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
  readonly property bool sourceUnavailable: selectedAddress !== "" && resolvedToplevel === null

  function refreshSource() {
    Hyprland.refreshToplevels()
    var list = Hyprland.toplevels.values
    var found = null
    var entries = []
    for (var i = 0; i < list.length; i++) {
      var toplevel = list[i]
      if (toplevel.title === "OmaPiP") continue
      entries.push(toplevel)
      if (toplevel.address === root.selectedAddress) found = toplevel
    }
    root.sourceEntries = entries
    root.resolvedToplevel = found
  }

  function open(payload) {
    root.refreshSource()
    var address = String(payload || "").trim()
    if (address !== "" && root.select(address) === "selected") return
    root.pickerVisible = true
  }

  function close() {
    root.pickerVisible = false
    root.viewerVisible = false
  }

  function select(address) {
    var wanted = String(address || "")
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
        appId: t.wayland ? t.wayland.appId : ""
      }
    }))
  }

  function state() {
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
      if (list[i].title === "OmaPiP") return list[i].address
    return ""
  }

  function configureViewer() {
    var address = viewerAddress()
    if (address === "") return
    var selector = "address:0x" + address
    var monitor = Hyprland.focusedMonitor
    var width = 640
    var height = 360
    var x = monitor ? monitor.x + monitor.width - width - 24 : 24
    var y = monitor ? monitor.y + monitor.height - height - 24 : 24
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
    title: "OmaPiP — choose a window"
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
              text: modelData.title || (modelData.wayland ? modelData.wayland.appId : "") || modelData.address
              color: "#ffffff"
              elide: Text.ElideRight
              font.pixelSize: 14
            }
            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              text: modelData.wayland ? modelData.wayland.appId : ""
              color: "#999999"
              font.pixelSize: 11
            }
            MouseArea {
              id: mouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: root.select(modelData.address)
            }
          }
        }
      }
    }
  }

  FloatingWindow {
    id: viewerWindow
    visible: root.viewerVisible
    title: "OmaPiP"
    implicitWidth: 640
    implicitHeight: 360
    minimumSize: Qt.size(160, 90)

    ScreencopyView {
      id: viewer
      anchors.fill: parent
      captureSource: root.resolvedToplevel ? root.resolvedToplevel.wayland : null
      live: true
      paintCursor: false
    }

    Rectangle {
      anchors.centerIn: parent
      visible: root.sourceUnavailable || !viewer.hasContent
      color: "#cc151515"
      radius: 4
      width: message.implicitWidth + 28
      height: message.implicitHeight + 18
      Text {
        id: message
        anchors.centerIn: parent
        text: root.sourceUnavailable ? "Source unavailable — choose another window" : "Waiting for capture…"
        color: "#ffffff"
        font.pixelSize: 14
      }
    }
  }
}
