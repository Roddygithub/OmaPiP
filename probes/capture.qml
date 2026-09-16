import QtQuick
import Quickshell
import Quickshell.Wayland

FloatingWindow {
  id: root
  visible: true
  title: "OmaPiP capture probe"
  implicitWidth: 480
  implicitHeight: 270
  minimumSize: Qt.size(160, 90)

  ScreencopyView {
    anchors.fill: parent
    captureSource: ToplevelManager.activeToplevel
    live: true
    paintCursor: false
    onHasContentChanged: console.log("capture hasContent=" + hasContent + " sourceSize=" + sourceSize.width + "x" + sourceSize.height)
    onStopped: console.log("capture stopped")
  }

  Component.onCompleted: console.log("capture source=" + (ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.title : "none"))
}
