pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "PanelLogic.js" as Logic

Item {
  id: root

  property string selectedAddress: ""
  property string pickerAnchorAddress: ""
  property var resolvedToplevel: null
  property var sourceEntries: []
  property bool pickerVisible: false
  property bool viewerVisible: false
  property bool viewerConfigured: false
  property bool viewerConfigPending: false
  property bool captureWaitExpired: false
  property int viewerConfigAttempts: 0
  property int viewerConfigGeneration: 0
  property int activeConfigGeneration: 0
  property bool hyprctlProcessReady: true
  property bool verifyProcessReady: true
  property bool hyprctlProcessBusy: false
  property bool verifyProcessBusy: false
  property bool hyprctlProcessExitHandled: false
  property bool verifyProcessExitHandled: false
  property bool hyprctlProcessStarted: false
  property bool verifyProcessStarted: false
  property bool hyprctlProcessCancelRequested: false
  property bool verifyProcessCancelRequested: false
  property string viewerConfigError: ""
  readonly property int maxViewerConfigAttempts: 3
  readonly property int maxPickerFocusAttempts: 20
  property int pickerFocusAttempts: 0
  property bool pickerFocusEstablished: false
  property bool sourceLost: false
  property bool viewerHovered: false
  property bool controlsHovered: false
  property bool controlsFocused: false
  property bool controlsVisible: false
  readonly property int controlsHideDelay: 280
  property int displayMode: 0  // 0 = Fill, 1 = Fit, 2 = Stretch
  readonly property string viewerTitle: "OmaPiP Viewer — io.github.roddygithub.omapip"
  readonly property string pickerTitle: "OmaPiP Picker — io.github.roddygithub.omapip"
  readonly property string viewerAppId: "org.quickshell"
  readonly property bool sourceUnavailable: selectedAddress !== ""
    && (sourceLost || resolvedToplevel === null)
  readonly property int modeFill: 0
  readonly property int modeFit: 1
  readonly property int modeStretch: 2

  function boundedText(value, limit) {
    return String(value || "").slice(0, limit)
  }

  function normalizeAddress(value) { return Logic.normalizeAddress(value) }

  function validAddress(value) {
    return root.normalizeAddress(value) !== ""
  }

  function isCapturableSource(toplevel) {
    return Logic.isCapturableSource(toplevel, root.viewerTitle, root.pickerTitle)
  }

  function boundedNumber(value, fallback, minimum, maximum) {
    return Logic.boundedNumber(value, fallback, minimum, maximum)
  }

  // Rebuild picker entries and source resolution from the live toplevel
  // model. Quickshell maintains that model from the Hyprland event socket,
  // so this reads current state without issuing any IPC of its own.
  function syncSources() {
    var list = Hyprland.toplevels.values
    var entries = []
    var capturableToplevels = []
    for (var i = 0; i < list.length; i++) {
      var toplevel = list[i]
      if (!root.isCapturableSource(toplevel)) continue
      capturableToplevels.push(toplevel)
      var address = root.normalizeAddress(toplevel.address)
      entries.push({
        address: address,
        title: root.boundedText(toplevel.title, 160),
        appId: root.boundedText(toplevel.wayland.appId, 80)
      })
    }
    var resolution = Logic.resolveSelectedSource(root.resolvedToplevel, root.sourceLost, capturableToplevels)
    root.sourceEntries = entries
    root.sourceLost = resolution.sourceLost
    root.resolvedToplevel = resolution.resolved
  }

  // Explicit refresh: force a hyprctl re-query, then sync. Reserved for
  // user actions and the slow fallback poll — the valuesChanged hook calls
  // syncSources() only, so model events can never re-enter refreshToplevels().
  function refreshSource() {
    Hyprland.refreshToplevels()
    root.syncSources()
  }

  function open(payload) {
    root.refreshSource()
    var address = String(payload || "").trim()
    if (address !== "" && root.select(address) === "selected") return
    root.showPicker()
  }

  function close() {
    root.pickerVisible = false
    root.viewerVisible = false
    root.cancelViewerConfiguration()
    root.viewerConfigured = false
    root.captureWaitExpired = false
    pickerFocusTimer.stop()
  }

  function chooseAnother() {
    root.refreshSource()
    root.showPicker()
  }

  function showPicker() {
    root.syncPickerSelection()
    root.pickerVisible = true
    root.pickerFocusAttempts = 0
    root.pickerFocusEstablished = false
    sourceList.forceActiveFocus()
    pickerFocusTimer.restart()
  }

  function setPickerSelection(index) {
    var clamped = Logic.boundedIndex(index, root.sourceEntries.length)
    sourceList.currentIndex = clamped
    root.pickerAnchorAddress = clamped >= 0 ? root.sourceEntries[clamped].address : ""
  }

  function movePickerSelection(delta) {
    root.setPickerSelection(sourceList.currentIndex + delta)
  }

  function syncPickerSelection() {
    root.setPickerSelection(Logic.indexForAddress(root.sourceEntries, root.selectedAddress))
  }

  function repairPickerSelection() {
    root.setPickerSelection(Logic.repairedIndex(sourceList.currentIndex, root.pickerAnchorAddress, root.sourceEntries))
  }

  function chooseFocusedSource() {
    var entries = root.sourceEntries
    var index = sourceList.currentIndex
    if (index < 0 || index >= entries.length) return
    root.select(entries[index].address)
  }

  function dismissPicker() {
    root.pickerVisible = false
    root.pickerAnchorAddress = ""
    pickerFocusTimer.stop()
  }

  onSourceEntriesChanged: if (root.pickerVisible) root.repairPickerSelection()

  function cycleDisplayMode() {
    root.displayMode = (root.displayMode + 1) % 3
    updateScreencopyViewGeometry()
  }

  function displayModeName() {
    if (root.displayMode === root.modeFill) return "Fill"
    if (root.displayMode === root.modeFit) return "Fit"
    return "Stretch"
  }

  function activateControl(action) {
    if (action === "Fill") root.cycleDisplayMode()
    else if (action === "Choose") root.chooseAnother()
    else root.close()
  }

  // Hover model: keep the toolbar visible while the pointer is over the
  // content OR over the toolbar itself. It fades out only after the pointer
  // leaves BOTH, using a short delay to avoid flicker when crossing to buttons.
  function evaluateControlsVisibility() {
    if (root.viewerHovered || root.controlsHovered || root.controlsFocused) {
      controlsHideTimer.stop()
      root.controlsVisible = true
    } else {
      controlsHideTimer.restart()
    }
  }

  onViewerHoveredChanged: root.evaluateControlsVisibility()
  onControlsHoveredChanged: root.evaluateControlsVisibility()

  function placeBottomRight() { placeAt(false) }
  function placeBottomLeft() { placeAt(true) }

  // Re-placement follows the monitor the viewer actually occupies — the
  // user may have dragged it away from the focused monitor.
  function viewerMonitor() {
    var screen = viewerWindow.screen
    var monitor = screen ? Hyprland.monitorFor(screen) : null
    return monitor || Hyprland.focusedMonitor
  }

  function placeAt(left) {
    var address = viewerAddress()
    var monitor = root.viewerMonitor()
    if (!root.validAddress(address) || !monitor) return
    var reserved = monitor.lastIpcObject && monitor.lastIpcObject.reserved || [0, 0, 0, 0]
    var transform = monitor.lastIpcObject && monitor.lastIpcObject.transform
    var workArea = Logic.monitorWorkArea(monitor.x, monitor.y, monitor.width, monitor.height,
      monitor.scale, transform, reserved)
    var width = root.boundedNumber(viewerWindow.width, 640, 160, 4000)
    var height = root.boundedNumber(viewerWindow.height, 360, 90, 4000)
    var margin = 24
    var minX = workArea.x + margin
    var maxX = workArea.x + workArea.w - width - margin
    var x = left ? minX : Math.max(minX, maxX)
    var y = Math.max(workArea.y + margin, workArea.y + workArea.h - height - margin)
    var selector = "address:0x" + address
    var command = "dispatch hl.dsp.window.move({ x = " + x + ", y = " + y
      + ", window = \"" + selector + "\" }); dispatch hl.dsp.window.alter_zorder({ mode = \"top\", window = \""
      + selector + "\" })"
    Quickshell.execDetached(["hyprctl", "--batch", command])
  }

  function select(address) {
    var wanted = root.normalizeAddress(address)
    if (wanted === "") return "invalid-address"
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++) {
      var toplevel = list[i]
      if (!root.isCapturableSource(toplevel)) continue
      if (root.normalizeAddress(toplevel.address) !== wanted) continue
      if (!root.viewerVisible) root.cancelViewerConfiguration()
      root.selectedAddress = wanted
      root.resolvedToplevel = toplevel
      root.sourceLost = false
      root.captureWaitExpired = false
      var configState = Logic.viewerConfigAfterSelect(root.viewerVisible, root.viewerConfigured, root.viewerConfigAttempts)
      root.viewerConfigured = configState.configured
      root.viewerConfigAttempts = configState.attempts
      root.viewerConfigError = ""
      root.pickerVisible = false
      root.pickerAnchorAddress = ""
      root.viewerVisible = true
      pickerFocusTimer.stop()
      return "selected"
    }
    return "address-not-found"
  }

  function sources() {
    return JSON.stringify(root.sourceEntries.map(function(t) {
      return { address: t.address, title: t.title, appId: t.appId }
    }))
  }

  function status() {
    var ww = viewerWindow.width || 0
    var wh = viewerWindow.height || 0
    var sw = screencopyView.sourceSize ? screencopyView.sourceSize.width : 0
    var sh = screencopyView.sourceSize ? screencopyView.sourceSize.height : 0
    var rt = root.resolvedToplevel
    var waylandObj = rt ? rt.wayland : null
    var captureSourceObj = screencopyView.captureSource
    return JSON.stringify({
      selectedAddress: root.selectedAddress,
      resolvedAddress: rt ? root.normalizeAddress(rt.address) : "",
      sourceUnavailable: root.sourceUnavailable,
      pickerVisible: root.pickerVisible,
      viewerVisible: root.viewerVisible,
      viewerConfigured: root.viewerConfigured,
      viewerConfigPending: root.viewerConfigPending,
      viewerConfigAttempts: root.viewerConfigAttempts,
      viewerConfigError: root.viewerConfigError,
      hasContent: screencopyView.hasContent,
      sourceSize: sw + "x" + sh,
      winSize: ww + "x" + wh,
      winAR: wh > 0 ? (ww / wh).toFixed(3) : "0",
      sourceAR: sh > 0 ? (sw / sh).toFixed(3) : "0",
      displayMode: root.displayModeName(),
      resolvedToplevelPresent: rt !== null,
      resolvedToplevelWaylandPresent: waylandObj !== null,
      waylandAppId: waylandObj ? waylandObj.appId : "",
      captureSourceMatches: captureSourceObj === waylandObj,
      captureSourcePresent: captureSourceObj !== null,
      viewSize: Math.round(screencopyView.width) + "x" + Math.round(screencopyView.height)
    })
  }

  function viewerAddress() {
    var list = Hyprland.toplevels.values
    for (var i = 0; i < list.length; i++) {
      var address = root.normalizeAddress(list[i].address)
      if (address !== "" && Logic.matchesViewer(list[i], root.viewerTitle, root.viewerAppId)) return address
    }
    return ""
  }

  function computeInitialSize() {
    var monitor = Hyprland.focusedMonitor
    if (!monitor) return { w: 560, h: 315 }
    var transform = monitor.lastIpcObject && monitor.lastIpcObject.transform
    var size = Logic.logicalMonitorSize(monitor.width, monitor.height, monitor.scale, transform)
    return Logic.initialViewerSize(size.w, size.h)
  }

  function cancelViewerConfiguration() {
    root.viewerConfigGeneration++
    if (hyprctlProcess.running) {
      root.hyprctlProcessCancelRequested = true
      hyprctlProcess.running = false
    }
    if (verifyProcess.running) {
      root.verifyProcessCancelRequested = true
      verifyProcess.running = false
    }
    // Termination is asynchronous; only onExited releases a process slot.
    root.viewerConfigPending = false
  }

  function timeoutViewerConfiguration() {
    root.cancelViewerConfiguration()
    root.viewerConfigError = "viewer configuration timed out"
  }

  function configurationClientMatches() {
    var clients
    try {
      clients = JSON.parse(verifyOutput.text || "[]")
    } catch (error) {
      return false
    }
    var address = root.normalizeAddress(root.viewerAddress())
    if (address === "" || !Array.isArray(clients)) return false
    for (var i = 0; i < clients.length; i++) {
      var client = clients[i]
      if (root.normalizeAddress(client.address) !== address) continue
      return client.floating === true && client.pinned === true
    }
    return false
  }

  function onConfigurationFailed() {
    if (!Logic.configurationGenerationIsCurrent(root.activeConfigGeneration, root.viewerConfigGeneration)) return
    root.viewerConfigPending = false
    root.viewerConfigError = "hyprctl configuration failed"
  }

  function onConfigurationExited(exitCode) {
    if (root.hyprctlProcessExitHandled) return
    root.hyprctlProcessExitHandled = true
    root.hyprctlProcessStarted = false
    root.hyprctlProcessCancelRequested = false
    root.hyprctlProcessBusy = false
    root.hyprctlProcessReady = true
    if (!Logic.configurationGenerationIsCurrent(root.activeConfigGeneration, root.viewerConfigGeneration)) return
    if (exitCode !== 0) {
      root.onConfigurationFailed()
      return
    }
    root.verifyProcessReady = false
    root.verifyProcessExitHandled = false
    root.verifyProcessStarted = false
    root.verifyProcessCancelRequested = false
    root.verifyProcessBusy = true
    verifyProcess.command = ["hyprctl", "clients", "-j"]
    verifyProcess.running = true
  }

  function onVerificationExited(exitCode) {
    if (root.verifyProcessExitHandled) return
    root.verifyProcessExitHandled = true
    root.verifyProcessStarted = false
    root.verifyProcessCancelRequested = false
    root.verifyProcessBusy = false
    root.verifyProcessReady = true
    if (!Logic.configurationGenerationIsCurrent(root.activeConfigGeneration, root.viewerConfigGeneration)) return
    root.viewerConfigPending = false
    if (exitCode === 0 && root.configurationClientMatches()) {
      root.viewerConfigured = true
      root.viewerConfigError = ""
    } else {
      root.viewerConfigError = "viewer configuration was not confirmed"
    }
  }

  function configureViewer() {
    var address = root.normalizeAddress(root.viewerAddress())
    if (address === "" || root.viewerConfigPending || root.viewerConfigAttempts >= root.maxViewerConfigAttempts
        || !root.hyprctlProcessReady || !root.verifyProcessReady
        || root.hyprctlProcessBusy || root.verifyProcessBusy) return
    var selector = "address:0x" + address
    var size = root.computeInitialSize()
    var width = size.w
    var height = size.h
    var monitor = Hyprland.focusedMonitor
    var reserved = monitor && monitor.lastIpcObject && monitor.lastIpcObject.reserved || [0, 0, 0, 0]
    var transform = monitor && monitor.lastIpcObject && monitor.lastIpcObject.transform
    var workArea = monitor ? Logic.monitorWorkArea(monitor.x, monitor.y, monitor.width, monitor.height,
      monitor.scale, transform, reserved) : { x: 0, y: 0, w: 1920, h: 1080 }
    var x = Math.max(workArea.x + 24, workArea.x + workArea.w - width - 24)
    var y = Math.max(workArea.y + 24, workArea.y + workArea.h - height - 24)
    var commands = [
      "dispatch hl.dsp.window.float({ action = \"enable\", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.pin({ action = \"enable\", window = \"" + selector + "\" })",
      "dispatch hl.dsp.window.alter_zorder({ mode = \"top\", window = \"" + selector + "\" })"
    ]
    if (Logic.isInitialViewerConfiguration(root.viewerConfigAttempts)) {
      commands.push("dispatch hl.dsp.window.resize({ x = " + width + ", y = " + height + ", window = \"" + selector + "\" })")
      commands.push("dispatch hl.dsp.window.move({ x = " + x + ", y = " + y + ", window = \"" + selector + "\" })")
    }
    root.viewerConfigAttempts++
    root.activeConfigGeneration = root.viewerConfigGeneration
    root.viewerConfigPending = true
    root.viewerConfigError = ""
    root.hyprctlProcessExitHandled = false
    root.hyprctlProcessStarted = false
    root.hyprctlProcessCancelRequested = false
    root.hyprctlProcessBusy = true
    root.hyprctlProcessReady = false
    hyprctlProcess.command = ["hyprctl", "--batch", commands.join("; ")]
    hyprctlProcess.running = true
  }

  function updateScreencopyViewGeometry() {
    if (!screencopyView.sourceSize || screencopyView.sourceSize.width <= 0 || screencopyView.sourceSize.height <= 0) return
    var vw = viewerContainer.width
    var vh = viewerContainer.height
    var sw = screencopyView.sourceSize.width
    var sh = screencopyView.sourceSize.height
    if (vw <= 0 || vh <= 0) return

    var size = Logic.displaySize(root.displayMode, vw, vh, sw, sh)
    screencopyView.width = size.w
    screencopyView.height = size.h
  }

  Connections {
    target: screencopyView
    function onSourceSizeChanged() {
      root.updateScreencopyViewGeometry()
    }
    function onHasContentChanged() {
      if (screencopyView.hasContent) root.captureWaitExpired = false
    }
  }

  // Recompute Fill/Fit/Stretch when the PiP window is resized (native resize
  // changes viewerContainer freely, and the view size must follow).
  Connections {
    target: viewerContainer
    function onWidthChanged() { root.updateScreencopyViewGeometry() }
    function onHeightChanged() { root.updateScreencopyViewGeometry() }
  }

  Timer {
    id: controlsHideTimer
    interval: root.controlsHideDelay
    repeat: false
    onTriggered: root.controlsVisible = false
  }

  // The picker's backing window does not exist yet when showPicker() runs, so
  // the first forceActiveFocus() is a no-op and the loader-hidden item chain
  // is not visible yet. Retry until the list actually holds activeFocus.
  Timer {
    id: pickerFocusTimer
    interval: 50
    repeat: true
    running: false
    onTriggered: {
      if (!root.pickerVisible || root.pickerFocusEstablished || root.pickerFocusAttempts >= root.maxPickerFocusAttempts) {
        pickerFocusTimer.stop()
        return
      }
      root.pickerFocusAttempts++
      sourceList.forceActiveFocus()
    }
  }

  Process {
    id: hyprctlProcess
    onStarted: root.hyprctlProcessStarted = true
    onRunningChanged: {
      if (!running && root.hyprctlProcessBusy) hyprctlStartFailureTimer.restart()
    }
    onExited: function(exitCode) { root.onConfigurationExited(exitCode) }
  }

  Process {
    id: verifyProcess
    stdout: StdioCollector {
      id: verifyOutput
      waitForEnd: true
    }
    onStarted: root.verifyProcessStarted = true
    onRunningChanged: {
      if (!running && root.verifyProcessBusy) verifyStartFailureTimer.restart()
    }
    onExited: function(exitCode) { root.onVerificationExited(exitCode) }
  }

  Timer {
    id: hyprctlStartFailureTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (!root.hyprctlProcessBusy || hyprctlProcess.running || root.hyprctlProcessStarted
          || root.hyprctlProcessExitHandled) return
      root.hyprctlProcessExitHandled = true
      root.hyprctlProcessBusy = false
      root.hyprctlProcessReady = true
      root.hyprctlProcessCancelRequested = false
      root.onConfigurationFailed()
    }
  }

  Timer {
    id: verifyStartFailureTimer
    interval: 100
    repeat: false
    onTriggered: {
      if (!root.verifyProcessBusy || verifyProcess.running || root.verifyProcessStarted
          || root.verifyProcessExitHandled) return
      root.verifyProcessExitHandled = true
      root.verifyProcessBusy = false
      root.verifyProcessReady = true
      root.verifyProcessCancelRequested = false
      if (Logic.configurationGenerationIsCurrent(root.activeConfigGeneration, root.viewerConfigGeneration)) {
        root.viewerConfigPending = false
        root.viewerConfigError = "viewer configuration process failed"
      }
    }
  }

  Timer {
    id: viewerConfigWatchdog
    interval: 5000
    running: root.viewerConfigPending
    repeat: false
    onTriggered: root.timeoutViewerConfiguration()
  }

  Timer {
    interval: 8000
    running: root.viewerVisible && root.resolvedToplevel !== null && !screencopyView.hasContent
      && !root.captureWaitExpired
    repeat: false
    onTriggered: root.captureWaitExpired = true
  }

  Timer {
    interval: 300
    running: root.viewerVisible && !root.viewerConfigured
      && !root.viewerConfigPending
      && root.viewerConfigAttempts < root.maxViewerConfigAttempts
    repeat: true
    onTriggered: root.configureViewer()
  }

  // Track window open/close churn without polling: Quickshell emits
  // valuesChanged whenever the toplevel model changes, giving immediate
  // source-loss detection. The slow fallback poll below still covers
  // wayland-handle attach timing and any missed event.
  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() {
      if (root.pickerVisible || root.viewerVisible) root.syncSources()
    }
  }

  Timer {
    interval: 2000
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
    onClosed: root.dismissPicker()

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
          focus: true
          keyNavigationEnabled: false
          Accessible.role: Accessible.List
          Accessible.name: "Capturable windows"

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) root.dismissPicker()
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.chooseFocusedSource()
            else if (event.key === Qt.Key_Down) root.movePickerSelection(1)
            else if (event.key === Qt.Key_Up) root.movePickerSelection(-1)
            else if (event.key === Qt.Key_Home) root.setPickerSelection(0)
            else if (event.key === Qt.Key_End) root.setPickerSelection(root.sourceEntries.length - 1)
            else { event.accepted = false; return }
            event.accepted = true
          }
          onActiveFocusChanged: if (sourceList.activeFocus) root.pickerFocusEstablished = true

          delegate: Rectangle {
            id: sourceDelegate
            required property var modelData
            required property int index
            width: sourceList.width
            height: 54
            radius: 5
            color: mouse.containsMouse ? "#3b3b3b"
              : (sourceDelegate.index === sourceList.currentIndex ? "#4a4a4a" : "#252525")
            border.width: sourceDelegate.index === sourceList.currentIndex ? 1 : 0
            border.color: "#8a8a8a"
            Accessible.role: Accessible.ListItem
            Accessible.name: (sourceDelegate.modelData.title || sourceDelegate.modelData.appId || sourceDelegate.modelData.address)
              + (sourceDelegate.modelData.appId ? ", " + sourceDelegate.modelData.appId : "")
            Accessible.selectable: true
            Accessible.selected: sourceDelegate.index === sourceList.currentIndex

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
              onClicked: {
                root.setPickerSelection(sourceDelegate.index)
                root.select(sourceDelegate.modelData.address)
              }
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
    implicitWidth: 560
    implicitHeight: 315
    minimumSize: Qt.size(160, 90)
    onClosed: {
      root.viewerVisible = false
      root.cancelViewerConfiguration()
      root.viewerConfigured = false
      root.captureWaitExpired = false
      root.controlsFocused = false
    }

    Rectangle {
      id: viewerContainer
      anchors.fill: parent
      color: "#000000"
      clip: true

      ScreencopyView {
        id: screencopyView
        anchors.centerIn: parent
        width: 1
        height: 1
        captureSource: root.resolvedToplevel ? root.resolvedToplevel.wayland : null
        live: true
        paintCursor: false
      }
    }

    // Body interaction: hover source + move + right-click (Choose).
    MouseArea {
      anchors.fill: parent
      z: 1
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onEntered: root.viewerHovered = true
      onExited: root.viewerHovered = false
      onPressed: function(event) {
        if (event.button === Qt.RightButton) root.chooseAnother()
        else viewerWindow.startSystemMove()
      }
    }

    // Native freeform resize: the compositor handles the drag, so geometry
    // always tracks the mouse and never fights a ratio-lock. Cursors come
    // from a passive HoverHandler so the edges stay hover-transparent and
    // never fade the controls while approaching them.
    MouseArea { x: 0; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeHorCursor }
      onPressed: viewerWindow.startSystemResize(Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 10; y: 12; width: 10; height: parent.height - 24; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeHorCursor }
      onPressed: viewerWindow.startSystemResize(Qt.RightEdge)
    }
    MouseArea { x: 12; y: 0; width: parent.width - 24; height: 10; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeVerCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge)
    }
    MouseArea { x: 12; y: parent.height - 10; width: parent.width - 24; height: 10; z: 2; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeVerCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge)
    }
    MouseArea { x: 0; y: 0; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeFDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 12; y: 0; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeBDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.TopEdge | Qt.RightEdge)
    }
    MouseArea { x: 0; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeBDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
    }
    MouseArea { x: parent.width - 12; y: parent.height - 12; width: 12; height: 12; z: 3; hoverEnabled: false
      HoverHandler { cursorShape: Qt.SizeFDiagCursor }
      onPressed: viewerWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }

    Rectangle {
      id: controls
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: 8
      // Stack above unavailableBox: at minimum window size the centered box
      // reaches the toolbar strip, and its click area must not swallow button hits.
      z: 5
      width: controlsRow.implicitWidth + 8
      height: 28
      color: "#cc151515"
      radius: 4
      opacity: root.controlsVisible ? 1.0 : 0.0
      visible: true
      Behavior on opacity {
        NumberAnimation { duration: root.viewerHovered || root.controlsHovered ? 120 : 175 }
      }

      // Track hover over the toolbar itself so it stays visible while the
      // pointer is here, independently of the content area.
      HoverHandler {
        id: controlsHoverArea
        onHoveredChanged: root.controlsHovered = controlsHoverArea.hovered
      }

      Row {
        id: controlsRow
        anchors.centerIn: parent
        spacing: 4
        Repeater {
          model: ["Fill", "Choose", "Close"]
          delegate: Rectangle {
            id: controlDelegate
            required property string modelData
            width: label.implicitWidth + 12
            height: 20
            radius: 3
            // Passive HoverHandler drives the highlight; it does NOT steal
            // hover from the parent overlay, so the controls stay visible.
            color: hover.hovered ? "#555555" : "#333333"
            Accessible.role: Accessible.Button
            Accessible.name: controlDelegate.modelData === "Fill"
              ? "Display mode: " + root.displayModeName()
              : (controlDelegate.modelData === "Choose" ? "Choose another source" : "Close picture-in-picture")
            Text { id: label; anchors.centerIn: parent; text: controlDelegate.modelData === "Fill" ? root.displayModeName() : controlDelegate.modelData; color: "#ffffff"; font.pixelSize: 11 }
            focus: controlDelegate.modelData === "Fill"
            activeFocusOnTab: true
            border.width: activeFocus ? 2 : 0
            border.color: "#ffffff"
            onActiveFocusChanged: {
              root.controlsFocused = activeFocus
              root.evaluateControlsVisibility()
            }
            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activateControl(controlDelegate.modelData)
                event.accepted = true
              } else event.accepted = false
            }
            Accessible.onPressAction: root.activateControl(controlDelegate.modelData)
            HoverHandler { id: hover }
            MouseArea {
              id: buttonMouse
              anchors.fill: parent
              enabled: root.controlsVisible || root.controlsFocused
              hoverEnabled: false
              onClicked: root.activateControl(controlDelegate.modelData)
            }
          }
        }
      }
    }

    Rectangle {
      id: unavailableBox
      anchors.centerIn: parent
      z: 4
      visible: root.viewerConfigError !== "" || root.captureWaitExpired || root.sourceUnavailable || !screencopyView.hasContent
      color: "#cc151515"
      radius: 4
      width: Math.min(parent.width - 20, 340)
      height: message.implicitHeight + 18
      Text {
        id: message
        width: parent.width - 28
        anchors.centerIn: parent
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: root.viewerConfigError !== "" ? "Viewer setup failed — close and reopen to retry"
          : (root.sourceUnavailable ? "Source unavailable — Choose another window"
            : (root.captureWaitExpired ? "Capture did not start — choose another window or reopen" : "Waiting for capture…"))
        color: "#ffffff"
        font.pixelSize: 14
        Accessible.role: Accessible.StaticText
        Accessible.name: message.text
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
