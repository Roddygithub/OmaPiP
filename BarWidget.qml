import QtQuick
import "./js"
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
    Binding {
        target: UpdateService
        property: "enabled"
        value: root.setting("checkUpdates", true) === true
    }
  moduleName: "io.github.roddygithub.omapip"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.pickerVisible || panelLoader.item.viewerVisible
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open("")
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    opened ? close() : open()
  }

  function status() { return panelLoader.item ? panelLoader.item.status() : "{}" }
  function sources() { return panelLoader.item ? panelLoader.item.sources() : "[]" }
  function select(address) { return panelLoader.item ? panelLoader.item.select(address) : "not-loaded" }
  function chooseAnother() { if (panelLoader.item) panelLoader.item.chooseAnother() }
  function placeBottomLeft() { if (panelLoader.item) panelLoader.item.placeBottomLeft() }
  function placeBottomRight() { if (panelLoader.item) panelLoader.item.placeBottomRight() }
  function cycleDisplayMode() { if (panelLoader.item) panelLoader.item.cycleDisplayMode() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: panelLoader
    // Omarchy instantiates bar widgets per monitor. These Panel instances
    // share one IPC target name, so CLI routing is not monitor-specific and
    // simultaneous viewers can interfere. A shared service entry point is
    // planned for a future release.
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
  }

  IpcHandler {
    target: "io.github.roddygithub.omapip"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function status(): string { return root.status() }
    function sources(): string { return root.sources() }
    function select(address: string): string { return root.select(address) }
    function chooseAnother(): void { root.chooseAnother() }
    function placeBottomLeft(): void { root.placeBottomLeft() }
    function placeBottomRight(): void { root.placeBottomRight() }
    function cycleDisplayMode(): void { root.cycleDisplayMode() }
  }

  Ui.BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    tooltipText: L10n.t("OmaPiP — Picture in Picture") + (UpdateService.available ? "\n" + UpdateService.notice : "")

    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }
    Rectangle {
        width: 7
        height: 7
        radius: 4
        color: Color.accent
        visible: UpdateService.available
        anchors.left: button.left
        anchors.top: button.top
        z: 11
    }
}
