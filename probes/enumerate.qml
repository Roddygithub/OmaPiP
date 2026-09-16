import QtQuick
import Quickshell
import Quickshell.Wayland

QtObject {
  property Timer timer: Timer {
    interval: 1500
    running: true
    repeat: false
    onTriggered: {
      console.log("OmaPiP enumeration probe: screens=" + Quickshell.screens.length)
      console.log("active=" + (ToplevelManager.activeToplevel ? ToplevelManager.activeToplevel.appId + " | " + ToplevelManager.activeToplevel.title : "none"))
      var list = ToplevelManager.toplevels.values
      console.log("toplevels=" + list.length)
      for (var i = 0; i < list.length; i++) {
        var t = list[i]
        console.log(i + ": appId=" + t.appId + " title=" + t.title + " activated=" + t.activated + " screens=" + t.screens.length)
      }
      Qt.quit()
    }
  }
}
