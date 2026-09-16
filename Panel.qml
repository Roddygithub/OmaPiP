import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
  id: root

  property string selectedAddress: ""
  property var resolvedToplevel: null
  property bool viewerVisible: false
  readonly property bool sourceUnavailable: selectedAddress !== "" && resolvedToplevel === null

  function refreshSource() {
    Hyprland.refreshToplevels()
    var list = Hyprland.toplevels.values
    var found = null
    for (var i = 0; i < list.length; i++) {
      if (list[i].address === root.selectedAddress) {
        found = list[i]
        break
      }
    }
    root.resolvedToplevel = found
  }

  function open(payload) {
    root.viewerVisible = true
    root.refreshSource()
  }

  function close() {
    root.viewerVisible = false
  }

  function select(address) {
    var wanted = String(address || "")
    if (wanted === "") return "address-required"
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++) {
      if (list[i].address === wanted) {
        root.selectedAddress = wanted
        root.resolvedToplevel = list[i]
        root.viewerVisible = true
        return "selected " + wanted
      }
    }
    return "address-not-found"
  }

  function sources() {
    return JSON.stringify(Hyprland.toplevels.values.map(function(t) {
      return { address: t.address, title: t.title, appId: t.wayland ? t.wayland.appId : "" }
    }))
  }

  function state() {
    return JSON.stringify({
      selectedAddress: root.selectedAddress,
      resolvedAddress: root.resolvedToplevel ? root.resolvedToplevel.address : "",
      sourceUnavailable: root.sourceUnavailable,
      viewerVisible: root.viewerVisible,
      hasContent: viewer.hasContent,
      sourceSize: viewer.sourceSize.width + "x" + viewer.sourceSize.height
    })
  }

  Timer {
    interval: 500
    running: root.viewerVisible
    repeat: true
    onTriggered: root.refreshSource()
  }

  FloatingWindow {
    id: window
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
  }
}
