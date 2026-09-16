import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Item {
  id: root
  property var source: null
  property string selectedAddress: ""

  function refresh() {
    Hyprland.refreshToplevels()
    var list = Hyprland.toplevels.values
    if (!root.source && list.length > 0) root.source = Hyprland.activeToplevel || list[0]
    root.selectedAddress = root.source ? root.source.address : ""
    console.log("HOST_PROBE toplevels=" + list.length + " active=" + (Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "none"))
  }

  function state() {
    var list = Hyprland.toplevels.values
    var windows = []
    for (var i = 0; i < list.length; i++) {
      var t = list[i]
      windows.push({
        address: t.address,
        title: t.title,
        activated: t.activated,
        workspace: t.workspace ? t.workspace.name : "",
        screen: t.monitor ? t.monitor.name : "",
        hasWayland: !!t.wayland,
        appId: t.wayland ? t.wayland.appId : ""
      })
    }
    return JSON.stringify({
      toplevels: windows,
      active: Hyprland.activeToplevel ? Hyprland.activeToplevel.address : "",
      source: root.source ? root.source.address : "",
      hasContent: viewer.hasContent,
      sourceSize: viewer.sourceSize.width + "x" + viewer.sourceSize.height
    })
  }

  function select(index) {
    var i = Math.floor(Number(index))
    var list = Hyprland.toplevels.values
    if (i < 0 || i >= list.length) return "invalid-index"
    root.source = list[i]
    root.selectedAddress = root.source.address
    return "selected " + root.source.address
  }

  Timer {
    interval: 750
    running: true
    repeat: true
    onTriggered: root.refresh()
  }


  FloatingWindow {
    id: window
    visible: true
    title: "OmaPiP host probe"
    implicitWidth: 480
    implicitHeight: 270
    minimumSize: Qt.size(160, 90)

    ScreencopyView {
      id: viewer
      anchors.fill: parent
      captureSource: root.source ? root.source.wayland : null
      live: true
      paintCursor: false
      onHasContentChanged: console.log("HOST_PROBE capture=" + hasContent + " size=" + sourceSize.width + "x" + sourceSize.height)
      onStopped: console.log("HOST_PROBE capture-stopped")
    }
  }
}
