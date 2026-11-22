pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Translation.js" as Translation

QtObject {
    id: root
    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"
    readonly property var registry: parse(registryFile.text())
    // Quickshell 0.3.2's FileView reads a whole file before anything can cap
    // it, so the language file is read through a bounded helper instead: at
    // most 256 bytes per poll, watching a file Omarchy rewrites on a choice.
    property string languageText: ""
    readonly property string languagePath: Quickshell.env("OMARCHY_LANGUAGE_FILE")
        || root.configHome + "/omarchy/language"
    readonly property string language: Translation.language(root.languageText,
        Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG"), registry)
    readonly property bool rightToLeft: ["ar", "fa", "he", "ur"].indexOf(language) >= 0
    readonly property string formatLocale: (registry[language] || {}).formatLocale || "en-US"
    readonly property var strings: parse(catalogFile.text())

    function parse(text) {
        try {
            var data = JSON.parse(text || "{}")
            return data && typeof data === "object" && !Array.isArray(data) ? data : ({})
        } catch (e) { return ({}) }
    }
    function t(source, args) { return Translation.translate(strings, source, args) }

    // Use Omarchy's persisted choice first; follow the session locale on older hosts.
    property Process languageReader: Process {
        command: ["/bin/sh", "-c", "head -c 256 -- \"$1\" 2>/dev/null || true", "sh", root.languagePath]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text !== root.languageText) root.languageText = text
            }
        }
    }

    // Editors and omarchy-language truncate then write, so the file is polled
    // twice a second; an intermediate empty read keeps the previous text.
    property Timer languagePoll: Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: {
            if (root.languageReader.running) return
            root.languageReader.running = true
        }
    }
    property FileView registryFile: FileView {
        path: decodeURIComponent(Qt.resolvedUrl("locales/registry.json").toString().replace(/^file:\/\//, ""))
        blockLoading: true
        printErrors: false
    }
    property FileView catalogFile: FileView {
        path: decodeURIComponent(Qt.resolvedUrl("locales/" + root.language + ".json").toString().replace(/^file:\/\//, ""))
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
}
