import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

// Bottom confirmation bar shown before a recording starts. It reports the
// canvas that will be captured and lets the user keep it, change it, cancel,
// or start.
//
// The window is exactly the size of the bar, so only the bar itself takes
// pointer input. Drag the bar body to move it; the position is remembered.
PanelWindow {
    id: root

    property var targetScreen: null
    property bool shown: false
    property string canvasLabel: ""
    property string targetLabel: ""
    property bool isRegion: true
    property string audioText: ""
    property string audioIcon: "volume_up"
    property bool audioOn: true
    property real savedX: -1
    property real savedY: -1

    signal startRequested()
    signal regionRequested()
    signal fullRequested()
    signal audioToggled()
    signal cancelRequested()
    signal positionChosen(real x, real y)

    // Top-left position of the bar on its screen, in logical pixels.
    property real dragX: 0
    property real dragY: 0
    property real grabOffsetX: 0
    property real grabOffsetY: 0

    readonly property real screenW: targetScreen ? targetScreen.width : 1920
    readonly property real screenH: targetScreen ? targetScreen.height : 1080
    readonly property real barW: Math.min(bar.implicitWidth, screenW - 16)
    readonly property real barH: bar.implicitHeight
    readonly property real defaultX: Math.max(0, (screenW - barW) / 2)
    readonly property real defaultY: Math.max(0, screenH - barH - 28)

    function clampX(value) {
        return Math.max(0, Math.min(value, screenW - barW));
    }

    function clampY(value) {
        return Math.max(0, Math.min(value, screenH - barH));
    }

    function placeBar() {
        if (savedX >= 0 && savedY >= 0) {
            dragX = clampX(savedX);
            dragY = clampY(savedY);
        } else {
            dragX = defaultX;
            dragY = defaultY;
        }
    }

    onShownChanged: {
        if (shown)
            Qt.callLater(placeBar);
    }

    onTargetScreenChanged: {
        if (shown)
            Qt.callLater(placeBar);
    }

    screen: targetScreen
    visible: shown && targetScreen !== null
    color: "transparent"

    WlrLayershell.namespace: "dms:dankrecorder-confirm"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors.bottom: true
    anchors.left: true
    implicitWidth: barW
    implicitHeight: barH

    WlrLayershell.margins {
        left: root.dragX
        bottom: Math.max(0, root.screenH - root.dragY - root.barH)
    }

    StyledRect {
        id: bar

        anchors.fill: parent
        implicitWidth: content.implicitWidth + Theme.spacingL * 2
        implicitHeight: Math.max(60, content.implicitHeight + Theme.spacingM * 2)
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh
        border.color: Theme.outlineMedium
        border.width: Theme.layerOutlineWidth

        // Drag handle. Declared first so the buttons above it win the clicks.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.SizeAllCursor

            onPressed: mouse => {
                const global = mapToItem(null, mouse.x, mouse.y);
                root.grabOffsetX = global.x - root.dragX;
                root.grabOffsetY = global.y - root.dragY;
            }

            onPositionChanged: mouse => {
                if (!pressed)
                    return;
                const global = mapToItem(null, mouse.x, mouse.y);
                root.dragX = root.clampX(global.x - root.grabOffsetX);
                root.dragY = root.clampY(global.y - root.grabOffsetY);
            }

            onReleased: root.positionChosen(root.dragX, root.dragY)
        }

        Row {
            id: content

            // Explicitly above the drag area, so buttons always win the click.
            z: 1
            anchors.centerIn: parent
            spacing: Theme.spacingS

            DankIcon {
                name: "videocam"
                size: Theme.iconSize
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StyledText {
                    text: root.canvasLabel
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    visible: text.length > 0
                    text: root.targetLabel
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            Item {
                width: Theme.spacingM
                height: 1
            }

            DankButton {
                text: I18n.trFor("dankRecorder", "Full screen")
                iconName: "fullscreen"
                enabled: root.isRegion
                backgroundColor: Theme.surfaceContainerHighest
                textColor: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.fullRequested()
            }

            DankButton {
                text: I18n.trFor("dankRecorder", "Region")
                iconName: "crop_free"
                backgroundColor: Theme.surfaceContainerHighest
                textColor: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.regionRequested()
            }

            DankButton {
                text: root.audioText
                iconName: root.audioIcon
                backgroundColor: Theme.surfaceContainerHighest
                textColor: root.audioOn ? Theme.surfaceText : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.audioToggled()
            }

            DankButton {
                text: I18n.trFor("dankRecorder", "Cancel")
                backgroundColor: Theme.surfaceContainerHighest
                textColor: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.cancelRequested()
            }

            DankButton {
                text: I18n.trFor("dankRecorder", "Start recording")
                iconName: "fiber_manual_record"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.startRequested()
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.cancelRequested()
    }
}
