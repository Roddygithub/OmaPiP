import QtQuick
import QtTest
import "../../PanelLogic.js" as Logic

// Runtime key-delivery contract for the picker pattern: a focused ListView
// with keyNavigationEnabled disabled receives the keys Panel.qml handles, and
// accepting them prevents Qt's own navigation from also moving currentIndex.
// This is a Qt-engine compatibility test, not a Quickshell/Hyprland
// integration test - live focus delivery stays human-validated.
TestCase {
    id: testCaseRoot
    name: "PickerKeys"
    when: windowShown
    width: 400
    height: 400

    property var entries: [
        { address: "aa", title: "A" },
        { address: "bb", title: "B" },
        { address: "cc", title: "C" }
    ]
    property int seen: 0

    ListView {
        id: list
        anchors.fill: parent
        model: testCaseRoot.entries
        focus: true
        keyNavigationEnabled: false
        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 40
            Text { text: modelData.title }
        }
        Keys.onPressed: function(event) {
            testCaseRoot.seen++
            if (event.key === Qt.Key_Down) {
                list.currentIndex = Logic.boundedIndex(list.currentIndex + 1, list.count)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Up) {
                list.currentIndex = Logic.boundedIndex(list.currentIndex - 1, list.count)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Home) {
                list.currentIndex = Logic.boundedIndex(0, list.count)
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_End) {
                list.currentIndex = Logic.boundedIndex(list.count - 1, list.count)
                event.accepted = true
                return
            }
            event.accepted = false
        }
    }

    function test_00_focus_and_key_delivery() {
        list.forceActiveFocus()
        verify(list.activeFocus, "ListView holds activeFocus after forceActiveFocus")
        testCaseRoot.seen = 0
        list.currentIndex = 0
        keyClick(Qt.Key_Down)
        compare(list.currentIndex, 1, "Down moves one step")
        keyClick(Qt.Key_Up)
        compare(list.currentIndex, 0, "Up moves back one step")
        keyClick(Qt.Key_Home)
        compare(list.currentIndex, 0, "Home selects first")
        keyClick(Qt.Key_End)
        compare(list.currentIndex, 2, "End selects last")
        compare(testCaseRoot.seen, 4, "every navigation key reached the handler")
        keyClick(Qt.Key_Return)
        keyClick(Qt.Key_Enter)
        keyClick(Qt.Key_Escape)
        compare(testCaseRoot.seen, 7, "Return, Enter and Escape reach the handler")
        keyClick(Qt.Key_A)
        compare(list.currentIndex, 2, "unhandled keys do not move the selection")
    }

    function test_01_bounds_are_clamped() {
        list.currentIndex = 2
        keyClick(Qt.Key_Down)
        compare(list.currentIndex, 2, "Down at the last source clamps")
        list.currentIndex = 0
        keyClick(Qt.Key_Up)
        compare(list.currentIndex, 0, "Up at the first source clamps")
    }

    function test_02_model_changes_keep_index_valid() {
        list.currentIndex = 2
        testCaseRoot.entries = [{ address: "aa", title: "A" }, { address: "bb", title: "B" }]
        wait(50)
        verify(list.currentIndex >= 0 && list.currentIndex < list.count,
               "index stays in bounds after the list shrinks")
        testCaseRoot.entries = []
        wait(50)
        compare(list.count, 0, "list is empty")
        compare(list.currentIndex, -1, "index is -1 on an empty list")
        keyClick(Qt.Key_Down)
        compare(list.currentIndex, -1, "Down on an empty list selects nothing")
        testCaseRoot.entries = [{ address: "aa", title: "A" }, { address: "bb", title: "B" }, { address: "cc", title: "C" }]
        wait(50)
        verify(list.currentIndex >= 0 && list.currentIndex < list.count,
               "index is valid again once sources reappear")
    }

    function test_99_cleanup() {
        testCaseRoot.entries = [{ address: "aa", title: "A" }, { address: "bb", title: "B" }, { address: "cc", title: "C" }]
        list.currentIndex = -1
    }
}
