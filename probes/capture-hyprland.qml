import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

FloatingWindow {
  id: root
  visible: true
  title: "OmaPiP capture probe"
  implicitWidth: 480
  implicitHeight: 270
  minimumSize: Qt.size(160, 90)
  property var source: null

  Timer {
    interval: 1000
    running: true
    repeat: false
    onTriggered: {
      Hyprland.refreshToplevels()
      var list = Hyprland.toplevels.values
      for (var i = 0; i < list.length; i++) {
        if (list[i].title !== root.title) { root.source = list[i]; break }
      }
      console.log("source address=" + (root.source ? root.source.address : "none") + " title=" + (root.source ? root.source.title : "none") + " wayland=" + (!!(root.source && root.source.wayland)))
    }
  }

  ScreencopyView {
    anchors.fill: parent
    captureSource: root.source ? root.source.wayland : null
    live: true
    paintCursor: false
    onHasContentChanged: console.log("capture hasContent=" + hasContent + " sourceSize=" + sourceSize.width + "x" + sourceSize.height)
    onStopped: console.log("capture stopped")
  }
}
