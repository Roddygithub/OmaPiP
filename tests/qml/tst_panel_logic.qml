import QtQuick
import QtTest
import "../../PanelLogic.js" as Logic

// This is a Qt JavaScript-engine compatibility smoke test, not a full
// Quickshell/Hyprland integration test.
TestCase {
    name: "PanelLogic"

    function test_normalizeAddress() {
        compare(Logic.normalizeAddress("  0x123ABC  "), "123abc")
        compare(Logic.normalizeAddress("123ABC"), "123abc")
        compare(Logic.normalizeAddress("0x"), "")
        compare(Logic.normalizeAddress("not-hex"), "")
        compare(Logic.normalizeAddress("1234567890abcdef0"), "")
    }

    function test_capturableSource() {
        var source = { address: "0xabc", title: "Terminal", wayland: { appId: "foot" } }
        compare(Logic.isCapturableSource(source, "Viewer", "Picker"), true)
        compare(Logic.isCapturableSource({ address: "0xabc", title: "Viewer", wayland: {} }, "Viewer", "Picker"), false)
        compare(Logic.isCapturableSource({ address: "0xabc", title: "Terminal", wayland: null }, "Viewer", "Picker"), false)
    }

    function test_displaySize() {
        var size = Logic.displaySize(0, 560, 315, 2536, 1030)
        compare(size.w, 776)
        compare(size.h, 315)
        size = Logic.displaySize(1, 560, 315, 635, 1030)
        compare(size.w, 194)
        compare(size.h, 315)
        size = Logic.displaySize(2, 400, 400, 2536, 1030)
        compare(size.w, 400)
        compare(size.h, 400)
        compare(Logic.displaySize(0, 0, 315, 635, 1030), null)
    }

    function test_initialViewerSize() {
        var size = Logic.initialViewerSize(1920, 1080)
        compare(size.w, 560)
        compare(size.h, 315)
        size = Logic.initialViewerSize(400, 200)
        compare(size.w, 240)
        compare(size.h, 135)
    }

    function test_boundedIndex() {
        compare(Logic.boundedIndex(-1, 0), -1)
        compare(Logic.boundedIndex(0, 0), -1)
        compare(Logic.boundedIndex(3, 0), -1)
        compare(Logic.boundedIndex(-1, 3), 0)
        compare(Logic.boundedIndex(0 + 1, 3), 1)
        compare(Logic.boundedIndex(2 + 1, 3), 2)
        compare(Logic.boundedIndex(0 - 1, 3), 0)
        compare(Logic.boundedIndex(99, 3), 2)
        compare(Logic.boundedIndex(0, 3), 0)
        compare(Logic.boundedIndex(3 - 1, 3), 2)
        compare(Logic.boundedIndex(2, 2), 1)
        compare(Logic.boundedIndex(0, 0), -1)
    }

    function test_indexForAddress() {
        var entries = [
            { address: "aaa", title: "Terminal", appId: "foot" },
            { address: "bbb", title: "Browser", appId: "firefox" }
        ]
        compare(Logic.indexForAddress(entries, "bbb"), 1)
        compare(Logic.indexForAddress(entries, "0xBBB"), 1)
        compare(Logic.indexForAddress(entries, ""), -1)
        compare(Logic.indexForAddress(entries, "ccc"), -1)
        compare(Logic.indexForAddress(entries, "Browser"), -1)
        compare(Logic.indexForAddress([], "bbb"), -1)
        compare(Logic.indexForAddress(null, "bbb"), -1)
        compare(Logic.boundedIndex(Logic.indexForAddress([], "bbb"), 0), -1)
        compare(Logic.boundedIndex(Logic.indexForAddress(entries, "ccc"), entries.length), 0)
    }
}
