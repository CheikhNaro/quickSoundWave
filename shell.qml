// ─────────────────────────────────────────────────────────────────────────────
// quickSoundWave — audio-reactive "mountain wave" bar for Quickshell
// Renders the spectrum produced by cava as a smooth gradient wave, pinned to
// the bottom of every screen as a click-through layershell surface.
// Works on any wlroots compositor (Hyprland, Umbriel, niri...).
// ─────────────────────────────────────────────────────────────────────────────
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

Scope {
    id: root

    // ══ CONFIG ══════════════════════════════════════════════════════════════
    property int bars: 20                  // number of wave control points
    property int framerate: 30             // cava analysis rate (fps)
    property int waveHeight: 200           // surface height in pixels
    property string audioMethod: "pulse"   // "pulse" (PipeWire) or "alsa"

    // Static colors — used as-is when syncColors is false,
    // and as fallback when the palette file is missing/incomplete.
    property bool syncColors: false
    property string paletteFile: ""        // resolved at startup, see below
    property string colorPrimary: "#758dd7"
    property string colorSecondary: "#836bc7"
    property string colorSurface: "#1a1c23"
    property string colorSurfaceDim: "#121317"
    // ═════════════════════════════════════════════════════════════════════════

    property var waveData: []
    signal paintRequested()

    // ─── Optional: live color sync from a palette file ───────────────────────
    // When syncColors is true, a small JS file holding the current palette is
    // watched and re-read on every change (see examples/noctalia-colors.js).
    Process {
        id: homeReader
        running: true
        command: ["sh", "-c", "echo $HOME"]
        stdout: StdioCollector {
            onStreamFinished: root.paletteFile = text.trim()
                + "/.cache/noctalia/quickSoundWave-colors.js"
        }
    }

    FileView {
        id: palette
        path: root.syncColors ? root.paletteFile : ""
        watchChanges: true
        onTextChanged: {
            root.colorPrimary = readColor("primary") || root.colorPrimary;
            root.colorSecondary = readColor("secondary") || root.colorSecondary;
            root.colorSurface = readColor("surface") || root.colorSurface;
            root.colorSurfaceDim = readColor("surfaceDim") || root.colorSurfaceDim;
            root.paintRequested();
        }

        function readColor(key) {
            var m = palette.text.match(new RegExp('(^|\\n)\\s*' + key + ':\\s*"([^"]+)"'));
            return m ? m[2] : null;
        }
    }

    // ─── Audio source (cava) ─────────────────────────────────────────────────
    Process {
        id: cavaProc
        running: true
        command: ["sh", "-c", `
            cava -p /dev/stdin <<EOF
[general]
bars = ${root.bars}
framerate = ${root.framerate}
autosens = 1

[input]
method = ${root.audioMethod}

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 1000
bar_delimiter = 59

[smoothing]
monstercat = 1.5
waves = 0
gravity = 100
noise_reduction = 0.20

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
EOF
        `]

        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";")
                    .map(p => parseFloat(p.trim()) / 1000)
                    .filter(p => !isNaN(p));

                if (points.length === 0) return;

                let old = root.waveData;
                if (old.length !== points.length) {
                    root.waveData = points;
                } else {
                    let smoothed = [];
                    for (let i = 0; i < points.length; i++) {
                        smoothed.push(old[i] + (points[i] - old[i]) * 0.3);
                    }
                    root.waveData = smoothed;
                }

                root.paintRequested();
            }
        }
    }

    // ─── One wave per screen ─────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            implicitHeight: root.waveHeight
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors {
                left: true
                right: true
                bottom: true
            }

            Canvas {
                id: canvas
                anchors.fill: parent

                Connections {
                    target: root
                    function onPaintRequested() {
                        canvas.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    drawWave(ctx, root.waveData);
                }

                function drawWave(ctx, data) {
                    if (!data || data.length < 2) return;

                    var gradient = ctx.createLinearGradient(0, 0, width, 0);
                    gradient.addColorStop(0.0, root.colorSurfaceDim);
                    gradient.addColorStop(0.3, root.colorPrimary);
                    gradient.addColorStop(0.6, root.colorSecondary);
                    gradient.addColorStop(1.0, root.colorPrimary);

                    ctx.beginPath();
                    ctx.globalAlpha = 1.0;
                    ctx.fillStyle = gradient;

                    ctx.moveTo(0, height);
                    ctx.lineTo(0, height - data[0] * height);

                    var step = width / (data.length - 1);
                    for (var i = 0; i < data.length - 1; i++) {
                        var xCurr = i * step;
                        var yCurr = height - data[i] * height;
                        var xMid = (xCurr + (i + 1) * step) / 2;
                        var yMid = (yCurr + (height - data[i + 1] * height)) / 2;
                        ctx.quadraticCurveTo(xCurr, yCurr, xMid, yMid);
                    }

                    ctx.lineTo((data.length - 1) * step, height - data[data.length - 1] * height);
                    ctx.lineTo(width, height);
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }
    }
}
