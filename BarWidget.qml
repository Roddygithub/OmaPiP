import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
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
    tooltipText: "OmaPiP — Picture in Picture"

    onPressed: function(button) {
      if (button === Qt.LeftButton) root.toggle()
    }
  }
}