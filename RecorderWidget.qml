import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    PluginGlobalVar { id: stateVar; varName: "state"; defaultValue: "idle" }
    PluginGlobalVar { id: elapsedVar; varName: "elapsed"; defaultValue: 0 }
    PluginGlobalVar { id: backendVar; varName: "backend"; defaultValue: "" }
    PluginGlobalVar { id: lastFileVar; varName: "lastFile"; defaultValue: "" }
    PluginGlobalVar { id: errorVar; varName: "error"; defaultValue: "" }
    PluginGlobalVar { id: canvasVar; varName: "canvas"; defaultValue: "" }

    readonly property string state: stateVar.value || "idle"
    readonly property int elapsed: elapsedVar.value || 0
    readonly property string backend: backendVar.value || ""
    readonly property string lastFile: lastFileVar.value || ""
    readonly property string canvas: canvasVar.value || ""
    readonly property bool active: state !== "idle"

    property bool _confirmStop: false

    // ── Helpers ────────────────────────────────────────────────────────────
    function call(fn) {
        Quickshell.execDetached([Proc.dmsBin, "ipc", "call", "dankRecorder", fn]);
    }

    function formatTime(seconds) {
        const s = Math.max(0, seconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const pad = n => (n < 10 ? "0" : "") + n;
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec);
    }

    readonly property string stateIcon: {
        switch (state) {
        case "armed": return "check_circle";
        case "starting": return "progress_activity";
        case "recording": return "stop_circle";
        case "paused": return "pause_circle";
        case "stopping": return "progress_activity";
        default: return "videocam";
        }
    }

    readonly property string primaryActionText: {
        if (state === "armed") return I18n.trFor("dankRecorder", "Start recording");
        if (active) return I18n.trFor("dankRecorder", "Stop");
        return I18n.trFor("dankRecorder", "Start");
    }

    readonly property string statusText: {
        switch (state) {
        case "armed": return I18n.trFor("dankRecorder", "Confirm") + (canvas ? " · " + canvas : "");
        case "starting": return I18n.trFor("dankRecorder", "Starting…");
        case "recording": return I18n.trFor("dankRecorder", "Recording") + " · " + formatTime(elapsed);
        case "paused": return I18n.trFor("dankRecorder", "Paused") + " · " + formatTime(elapsed);
        case "stopping": return I18n.trFor("dankRecorder", "Saving…");
        default: return lastFile ? I18n.trFor("dankRecorder", "Ready") : I18n.trFor("dankRecorder", "Tap to record");
        }
    }

    function toggleRecord() {
        if (state === "armed") {
            call("confirm");
            return;
        }
        if (state === "idle") {
            call("start");
            return;
        }
        if (state === "starting" || state === "stopping")
            return;
        if (!_confirmStop) {
            _confirmStop = true;
            confirmTimer.restart();
            return;
        }
        confirmTimer.stop();
        _confirmStop = false;
        call("stop");
    }

    Timer {
        id: confirmTimer
        interval: 3000
        repeat: false
        onTriggered: root._confirmStop = false
    }

    // ── Bar pill ───────────────────────────────────────────────────────────
    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            Item {
                width: root.iconSize
                height: root.iconSize
                anchors.verticalCenter: parent.verticalCenter

                RotationAnimator on rotation {
                    running: root.state === "starting" || root.state === "stopping"
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: root._confirmStop ? "stop_circle" : root.stateIcon
                    size: root.iconSize
                    color: root._confirmStop ? Theme.warning
                        : root.state === "recording" ? Theme.error
                        : root.state === "paused" ? Theme.warning
                        : root.state === "idle" ? Theme.widgetIconColor
                        : Theme.primary
                }
            }

            StyledText {
                visible: root.active
                anchors.verticalCenter: parent.verticalCenter
                text: root._confirmStop ? I18n.trFor("dankRecorder", "Stop?")
                    : root.state === "armed" ? I18n.trFor("dankRecorder", "Start?")
                    : root.formatTime(root.elapsed)
                color: root._confirmStop ? Theme.warning : Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            Item {
                width: root.iconSize
                height: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter

                DankIcon {
                    anchors.centerIn: parent
                    name: root._confirmStop ? "stop_circle" : root.stateIcon
                    size: root.iconSize
                    color: root._confirmStop ? Theme.warning
                        : root.state === "recording" ? Theme.error
                        : root.state === "paused" ? Theme.warning
                        : root.state === "idle" ? Theme.widgetIconColor
                        : Theme.primary
                }
            }

            StyledText {
                visible: root.active && root.state !== "armed"
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.formatTime(root.elapsed)
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
            }
        }
    }

    // Exactly as before: left-click toggles, right-click asks for the popout.
    pillClickAction: () => root.toggleRecord()
    pillRightClickAction: () => root.triggerPopout()

    // ── Popout ─────────────────────────────────────────────────────────────
    popoutWidth: 380
    popoutHeight: 300

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: I18n.trFor("dankRecorder", "Dank Recorder")
            detailsText: root.active
                ? root.statusText + (root.backend ? " · " + root.backend : "")
                : I18n.trFor("dankRecorder", "Start or stop a recording. Use Region to pick the canvas.")
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledRect {
                    width: parent.width
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    implicitHeight: infoColumn.implicitHeight + Theme.spacingM * 2

                    Column {
                        id: infoColumn
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        StyledText {
                            text: root.state === "armed" ? root.canvas : (root.active ? root.formatTime(root.elapsed) : I18n.trFor("dankRecorder", "Idle"))
                            font.pixelSize: Theme.fontSizeXLarge
                            font.weight: Font.Bold
                            color: root.state === "recording" ? Theme.error : Theme.surfaceText
                        }

                        StyledText {
                            width: parent.width
                            text: root.backend ? I18n.trFor("dankRecorder", "Encoder") + ": " + root.backend : " "
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            width: parent.width
                            visible: root.lastFile.length > 0
                            text: I18n.trFor("dankRecorder", "Last file") + ": " + root.lastFile
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                        }

                        StyledText {
                            width: parent.width
                            visible: !root.active && root.lastFile.length === 0 && (errorVar.value || "").length > 0
                            text: errorVar.value || ""
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.error
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }

                Row {
                    spacing: Theme.spacingM

                    DankButton {
                        text: root.primaryActionText
                        enabled: root.state !== "starting" && root.state !== "stopping"
                        onClicked: {
                            root.toggleRecord();
                            popout.closePopout();
                        }
                    }

                    DankButton {
                        text: root.state === "paused" ? I18n.trFor("dankRecorder", "Resume") : I18n.trFor("dankRecorder", "Pause")
                        enabled: root.state === "recording" || root.state === "paused"
                        onClicked: root.call("pause")
                    }

                    DankButton {
                        text: I18n.trFor("dankRecorder", "Region")
                        enabled: root.state === "idle"
                        onClicked: {
                            root.call("startRegion");
                            popout.closePopout();
                        }
                    }
                }

                Row {
                    spacing: Theme.spacingM

                    DankButton {
                        text: I18n.trFor("dankRecorder", "Open folder")
                        onClicked: root.call("openFolder")
                    }

                    DankButton {
                        text: I18n.trFor("dankRecorder", "Open last")
                        enabled: root.lastFile.length > 0
                        onClicked: root.call("openLast")
                    }
                }
            }
        }
    }

    // ── Control center tile ────────────────────────────────────────────────
    ccWidgetIcon: root.stateIcon
    ccWidgetPrimaryText: I18n.trFor("dankRecorder", "Dank Recorder")
    ccWidgetSecondaryText: root.statusText
    ccWidgetIsActive: root.active
    ccWidgetIsToggle: true
    onCcWidgetToggled: root.toggleRecord()
}
