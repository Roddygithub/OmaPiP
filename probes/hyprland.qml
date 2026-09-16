import QtQuick
import Quickshell
import Quickshell.Hyprland

QtObject {
  property Timer timer: Timer {
    interval: 1200
    running: true
    repeat: false
    onTriggered: {
      Hyprland.refreshToplevels()
      var list = Hyprland.toplevels.values
      console.log("Hyprland toplevels=" + list.length)
      for (var i = 0; i < list.length; i++) {
        var t = list[i]
        console.log(i + ": address=" + t.address + " title=" + t.title + " active=" + t.activated + " wayland=" + (!!t.wayland))
      }
      var active = Hyprland.activeToplevel
      console.log("active address=" + (active ? active.address : "none") + " wayland=" + (!!(active && active.wayland)))
      Qt.quit()
    }
  }
}
