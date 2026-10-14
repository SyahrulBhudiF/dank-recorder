import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "dankRecorder"

    property string detectedGpus: PluginService.getGlobalVar("dankRecorder", "gpus", "")
    property string detectedCaps: PluginService.getGlobalVar("dankRecorder", "caps", "")
    property string captureTarget: loadValue("captureTarget", "focused")

    Connections {
        target: PluginService

        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId !== "dankRecorder")
                return;
            if (varName === "gpus")
                root.detectedGpus = PluginService.getGlobalVar("dankRecorder", "gpus", "");
            else if (varName === "caps")
                root.detectedCaps = PluginService.getGlobalVar("dankRecorder", "caps", "");
        }
    }

    StyledText {
        width: parent.width
        text: I18n.trFor("dankRecorder", "Dank Recorder")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: I18n.trFor("dankRecorder", "Records with gpu-screen-recorder. Hardware encoding is used when the GPU offers it; otherwise the recording continues on the CPU, so it works with the discrete GPU powered off.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: root.detectedGpus.length > 0
            ? I18n.trFor("dankRecorder", "Detected GPUs: %1").arg(root.detectedGpus)
            : I18n.trFor("dankRecorder", "No DRM devices detected yet.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        visible: root.detectedCaps.length > 0
        text: I18n.trFor("dankRecorder", "Hardware encoders: %1").arg(root.detectedCaps)
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "confirmBeforeStart"
        label: I18n.trFor("dankRecorder", "Confirm before recording")
        description: I18n.trFor("dankRecorder", "Show a bar at the bottom of the screen with the canvas size and Start and Cancel buttons before the recording begins. Use it to pick the region and to check the canvas.")
        defaultValue: true
    }

    SelectionSetting {
        id: targetSetting
        settingKey: "captureTarget"
        label: I18n.trFor("dankRecorder", "Capture target")
        description: I18n.trFor("dankRecorder", "What the bar icon and the control center tile record.")
        options: [
            { label: I18n.trFor("dankRecorder", "Focused output"), value: "focused" },
            { label: I18n.trFor("dankRecorder", "First monitor"), value: "primary" },
            { label: I18n.trFor("dankRecorder", "Selected monitor"), value: "monitor" },
            { label: I18n.trFor("dankRecorder", "Select a region"), value: "region" },
            { label: I18n.trFor("dankRecorder", "Desktop portal"), value: "portal" }
        ]
        defaultValue: "focused"
        onValueChanged: root.captureTarget = value
    }

    StringSetting {
        settingKey: "monitor"
        label: I18n.trFor("dankRecorder", "Monitor name")
        description: I18n.trFor("dankRecorder", "Connector name, for example eDP-1 or HDMI-A-1. Run gpu-screen-recorder --list-monitors to list them.")
        placeholder: "eDP-1"
        defaultValue: ""
        visible: root.captureTarget === "monitor"
    }

    SelectionSetting {
        settingKey: "fps"
        label: I18n.trFor("dankRecorder", "Frame rate")
        description: I18n.trFor("dankRecorder", "Frames per second.")
        options: [
            { label: "30", value: "30" },
            { label: "60", value: "60" },
            { label: "120", value: "120" }
        ]
        defaultValue: "60"
    }

    SelectionSetting {
        settingKey: "quality"
        label: I18n.trFor("dankRecorder", "Quality")
        description: I18n.trFor("dankRecorder", "Constant-quality preset. Ultra produces larger files and costs more CPU on the software encoder.")
        options: [
            { label: I18n.trFor("dankRecorder", "Medium"), value: "medium" },
            { label: I18n.trFor("dankRecorder", "High"), value: "high" },
            { label: I18n.trFor("dankRecorder", "Very high"), value: "very_high" },
            { label: I18n.trFor("dankRecorder", "Ultra"), value: "ultra" }
        ]
        defaultValue: "very_high"
    }

    SelectionSetting {
        settingKey: "codec"
        label: I18n.trFor("dankRecorder", "Video codec")
        description: I18n.trFor("dankRecorder", "H.264 is the most compatible and avoids the AMD black-bar bug with HEVC and AV1.")
        options: [
            { label: "H.264", value: "h264" },
            { label: "HEVC (H.265)", value: "hevc" },
            { label: "AV1", value: "av1" }
        ]
        defaultValue: "h264"
    }

    SelectionSetting {
        settingKey: "container"
        label: I18n.trFor("dankRecorder", "Container")
        description: I18n.trFor("dankRecorder", "MKV tolerates interrupted recordings better than MP4.")
        options: [
            { label: "MP4", value: "mp4" },
            { label: "MKV", value: "mkv" }
        ]
        defaultValue: "mp4"
    }

    SelectionSetting {
        settingKey: "audioSource"
        label: I18n.trFor("dankRecorder", "Audio")
        description: I18n.trFor("dankRecorder", "Recorded through PipeWire. The Sound button on the canvas bar mutes and unmutes without changing this.")
        options: [
            { label: I18n.trFor("dankRecorder", "None"), value: "none" },
            { label: I18n.trFor("dankRecorder", "Desktop output"), value: "output" },
            { label: I18n.trFor("dankRecorder", "Desktop output and microphone"), value: "both" },
            { label: I18n.trFor("dankRecorder", "Microphone only"), value: "input" }
        ]
        defaultValue: "output"
    }

    ToggleSetting {
        settingKey: "recordCursor"
        label: I18n.trFor("dankRecorder", "Record the cursor")
        description: I18n.trFor("dankRecorder", "Include the mouse pointer in the video.")
        defaultValue: true
    }

    SelectionSetting {
        settingKey: "encoderMode"
        label: I18n.trFor("dankRecorder", "Encoder")
        description: I18n.trFor("dankRecorder", "Auto uses the GPU encoder and drops to the CPU when it is unavailable. CPU forces software encoding.")
        options: [
            { label: I18n.trFor("dankRecorder", "Auto (GPU, then CPU)"), value: "auto" },
            { label: I18n.trFor("dankRecorder", "CPU only"), value: "cpu" }
        ]
        defaultValue: "auto"
    }

    SelectionSetting {
        settingKey: "gpuPreference"
        label: I18n.trFor("dankRecorder", "GPU preference")
        description: I18n.trFor("dankRecorder", "Best effort. gpu-screen-recorder encodes on the GPU that drives the captured monitor. If the preferred GPU is unavailable or fails, the recording retries on the default GPU and then on the CPU.")
        options: [
            { label: I18n.trFor("dankRecorder", "Automatic"), value: "auto" },
            { label: I18n.trFor("dankRecorder", "AMD"), value: "amd" },
            { label: I18n.trFor("dankRecorder", "NVIDIA"), value: "nvidia" },
            { label: I18n.trFor("dankRecorder", "Intel"), value: "intel" }
        ]
        defaultValue: "auto"
    }

    ToggleSetting {
        settingKey: "lowPower"
        label: I18n.trFor("dankRecorder", "Low power mode (AMD)")
        description: I18n.trFor("dankRecorder", "Lets the AMD GPU drop to a lower power state while recording. Only affects AMD.")
        defaultValue: false
    }

    ToggleSetting {
        settingKey: "notify"
        label: I18n.trFor("dankRecorder", "Notifications")
        description: I18n.trFor("dankRecorder", "Show a toast when a recording starts, stops, or fails.")
        defaultValue: true
    }

    StringSetting {
        settingKey: "outputDir"
        label: I18n.trFor("dankRecorder", "Output folder")
        description: I18n.trFor("dankRecorder", "Leave empty for ~/Videos/Screencasts.")
        placeholder: I18n.trFor("dankRecorder", "~/Videos/Screencasts")
        defaultValue: ""
    }
}
