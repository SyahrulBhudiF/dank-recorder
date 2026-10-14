import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand("dankRecorder.depCheck", ["sh", "-c", "command -v gpu-screen-recorder"], (output, exitCode) => {
            if (exitCode === 0)
                return done(null);

            done({
                title: I18n.trFor("dankRecorder", "gpu-screen-recorder is required"),
                details: I18n.trFor("dankRecorder", "Install it, then enable this plugin again:\n\nFedora: sudo dnf install gpu-screen-recorder\nArch: sudo pacman -S gpu-screen-recorder\nDebian/Ubuntu: sudo apt install gpu-screen-recorder-cli\n\nUse the native package, not the Flatpak GUI build.")
            });
        }, 0, 5000);
    }
}
