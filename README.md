# Dank Recorder

A screen recorder plugin for [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell)
(DMS). It drives [`gpu-screen-recorder`](https://git.dec05eba.com/gpu-screen-recorder/about) and
adds a bar icon, a control center tile, and IPC commands.

The plugin works with an AMD integrated GPU while the discrete NVIDIA GPU is powered off. It also
works when NVIDIA is enabled. If a hardware encoder is missing or fails, the recording continues on
the CPU, so recording never depends on one GPU.

## Why other recorders failed

Two common causes on Fedora and niri:

1. **No hardware encoder is available.** Fedora ships Mesa without the AMD H.264 and H.265 encode
   paths. `gpu-screen-recorder` refuses to record by default when the requested hardware codec is
   missing. This plugin always passes `-fallback-cpu-encoding yes`, so the CPU encoder takes over.
2. **No desktop portal is running.** Recorders that capture through `xdg-desktop-portal` fail when
   the portal service is not started. This also affects OBS on Wayland. This plugin captures the
   monitor directly through KMS, which does not need the portal.

## Requirements

- Dank Material Shell 1.6.0 or later
- `gpu-screen-recorder` on `PATH` (the native package, not the Flatpak GUI build)
- `slurp` for region selection (optional)
- A working PipeWire session for audio (optional)

Install `gpu-screen-recorder`:

```bash
# Fedora
sudo dnf install gpu-screen-recorder

# Arch Linux
sudo pacman -S gpu-screen-recorder

# Debian and Ubuntu
sudo apt install gpu-screen-recorder-cli
```

## Install

```bash
git clone https://github.com/<you>/dms-recorder ~/Projects/dms-recorder
ln -sfn ~/Projects/dms-recorder ~/.config/DankMaterialShell/plugins/dankRecorder
dms restart
```

Then open Settings, go to Plugins, and enable **Dank Recorder**.

## Use

| Action | Result |
| --- | --- |
| Left-click the bar icon | Start. A confirmation bar appears first. |
| Right-click the bar icon | Open the popout with all controls. |
| Control center tile | Click to run the recorder and show the canvas bar. |

The first click on a recording icon shows `Stop?`. Click again within 3 seconds to stop.

### Canvas confirmation

Before a recording starts, a bar appears at the bottom of the focused screen. It shows
the canvas that will be captured and offers four actions:

| Button | Result |
| --- | --- |
| Full screen | Capture the focused output. |
| Region | Select the canvas with `slurp`. |
| Sound / Muted | Include desktop audio, or mute. The source comes from the Audio setting. |
| Cancel | Discard the pending recording. |
| Start recording | Begin the recording. |

The bar does not take over the screen: only the bar itself takes pointer input. Drag its body
to move it; the plugin remembers where you put it. Use it to check the canvas size before you
start. Turn the step off with **Confirm before recording** in the settings.

The plugin saves files in `~/Videos/Screencasts` by default. Set another folder in the settings.

### Keybinds

Add a keybind to your niri configuration:

```kdl
binds {
    Mod+Shift+R { spawn "dms" "ipc" "call" "dankRecorder" "toggle"; }
    Mod+Shift+S { spawn "dms" "ipc" "call" "dankRecorder" "startRegion"; }
}
```

### IPC commands

```bash
dms ipc call dankRecorder start          # Resolve the target, then show the confirmation bar
dms ipc call dankRecorder startRegion    # Select a region, then show the confirmation bar
dms ipc call dankRecorder startPortal    # Start through the desktop portal
dms ipc call dankRecorder confirm        # Start the pending recording
dms ipc call dankRecorder cancel         # Discard the pending recording
dms ipc call dankRecorder reselect       # Select the region again
dms ipc call dankRecorder fullscreen     # Use the focused output as the canvas
dms ipc call dankRecorder stop           # Stop and save
dms ipc call dankRecorder toggle         # Start or stop
dms ipc call dankRecorder pause          # Pause or resume
dms ipc call dankRecorder toggleAudio    # Mute or unmute for the next recording
dms ipc call dankRecorder status         # Print the current state as JSON
dms ipc call dankRecorder openFolder     # Open the output folder
dms ipc call dankRecorder openLast       # Open the last recording
```

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Confirm before recording | On | Show the bottom canvas bar before each recording. |
| Capture target | Focused output | Focused output, first monitor, a named monitor, a region, or the portal. |
| Monitor name | empty | Connector name such as `eDP-1` or `HDMI-A-1`. |
| Frame rate | 60 | 30, 60, or 120 FPS. |
| Quality | Very high | Constant-quality preset. |
| Video codec | H.264 | HEVC and AV1 can produce black bars on AMD. |
| Container | MP4 | MKV survives an interrupted recording better. |
| Audio | Desktop output | None, desktop output, output and microphone, or microphone. The bar's Sound button mutes and unmutes without changing this. |
| Record the cursor | On | Include the mouse pointer. |
| Encoder | Auto | Auto uses the GPU encoder and drops to the CPU. CPU forces software encoding. |
| GPU preference | Automatic | Best effort. See below. |
| Low power mode | Off | Lets the AMD GPU drop to a lower power state. |
| Notifications | On | Show a toast when a recording starts, stops, or fails. |
| Output folder | empty | Defaults to `~/Videos/Screencasts`. |

## How the GPU fallback works

`gpu-screen-recorder` encodes on the GPU that drives the captured monitor. It cannot encode on an
arbitrary GPU.

The plugin therefore uses two mechanisms:

1. **GPU preference.** When you select AMD or NVIDIA, the plugin pins that DRM device with the
   `DRI_PRIME` environment variable. If the device is absent, the driver ignores the request and
   uses the default GPU.
2. **Encoder fallback.** Every attempt passes `-fallback-cpu-encoding yes`. If no GPU encoder is
   usable, the encoder drops to the CPU.

The plugin also keeps a candidate list. If the preferred candidate exits during a 2.5-second probe,
the plugin retries the next candidate. The last candidate always includes the CPU fallback, so a
recording always starts unless the capture source itself is invalid.

This is why the plugin records on the AMD iGPU with NVIDIA powered off, and why it still works after
you enable NVIDIA.

## Enable AMD hardware encoding on Fedora

Fedora disables AMD H.264 and H.265 hardware encoding in Mesa for patent reasons. To enable it,
install the RPM Fusion replacement package and reboot:

```bash
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld
```

After the reboot, `gpu-screen-recorder --info` lists `h264` and `hevc` instead of `h264_software`.
NVIDIA encoding needs no change; install the NVIDIA driver and enable the GPU.

## Troubleshooting

- **The recording starts, then stops in a few seconds.** The capture source is invalid. Select
  **Focused output** or a named monitor. Run `gpu-screen-recorder --list-monitors` to list monitors.
- **The video shows black bars.** Use H.264.
- **No audio in the file.** Check the audio source in the settings and confirm PipeWire runs:
  `systemctl --user status pipewire`.
- **The plugin reports a missing binary.** Install `gpu-screen-recorder` and enable the plugin again.

## License

MIT. See [LICENSE](LICENSE).
