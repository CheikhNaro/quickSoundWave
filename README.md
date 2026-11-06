# quickSoundWave

https://github.com/user-attachments/assets/7f43c0df-4fa2-4805-b098-d1e7de9047c9


An audio-reactive "mountain wave" for your Wayland desktop. A single
[Quickshell](https://quickshell.org) overlay that reads your system audio with
[cava](https://github.com/karlstav/cava) and paints a smooth spectrum wave
anchored to the bottom of every screen — click-through, excluded from the
struts, and compositor-agnostic.

<!-- TODO: drop a screenshot or screen recording in docs/ and link it here,
     e.g. ![preview](docs/preview.gif) -->

## Features

- 🎵 Live spectrum → bezier-smoothed mountain wave, one per monitor
- 🖱️ Fully transparent input: `Bottom` layer, `ExclusionMode.Ignore`, no keyboard focus
- 🎨 Static colors out of the box, optional live palette sync (Noctalia-ready)
- 🧩 Zero compositor lock-in: anything that speaks layer-shell (Hyprland, Umbriel, niri, river, labwc…)

## Dependencies

| Package | Why |
|---|---|
| `quickshell` ≥ 0.2 | QML runtime for the overlay |
| `cava` | Console audio visualizer used as the spectrum source |
| `pipewire-pulse` *(or `pulseaudio`)* | `pulse` input method for cava — swap to `alsa` if you have neither |

<details>
<summary>Install commands</summary>

**Fedora** — quickshell ships in a COPR:

```sh
sudo dnf copr enable errornointernet/quickshell
sudo dnf install quickshell cava
# pipewire-pulse is installed by default on Fedora workstations
```

**Arch Linux / EndeavourOS:**

```sh
sudo pacman -S quickshell cava pipewire-pulse
```

**Nix / NixOS** (system or user packages):

```nix
environment.systemPackages = [ pkgs.quickshell pkgs.cava ];
# or: nix-shell -p quickshell cava
```

**Other distros:** grab a Quickshell release from its repo, and cava from your
package manager (it's widely packaged).
</details>

## Install

Quickshell discovers configs as named folders under the XDG config dirs:

```sh
mkdir -p ~/.config/quickshell
git clone https://github.com/CheikhNaro/quickSoundWave.git ~/.config/quickshell/quickSoundWave
```

Test it by hand first:

```sh
qs -c quickSoundWave
```

You should see the wave react to any audio playing in your session. Quit it
with `Ctrl+C` before adding the autostart entry below.

## Launch at session start

Pick the section for your compositor — the command is the same everywhere,
only *where* it goes changes.

### Hyprland

`~/.config/hypr/hyprland.conf`:

```ini
exec-once = qs -c quickSoundWave
```

### Umbriel

In the Umbriel configuration file (`~/.config/umbriel/config.toml`), add it to
the session `autostart` list:

```toml
autostart = ["qs -c quickSoundWave"]
```

Changes to `autostart` apply on next session start (a full restart is needed).

### niri

`~/.config/niri/config.kdl`:

```kdl
spawn-at-start "qs -c quickSoundWave"
```

Apply with `niri msg action reload-config` or log out/in.

> 💡 If your compositor restarts configs without killing processes (Hyprland
> `exec-once` on reload, etc.), add the `-n` flag (`qs -c quickSoundWave -n`)
> so extra instances refuse to start instead of stacking waves.

## Configuration

Everything lives at the top of [`shell.qml`](shell.qml):

| Property | Default | Meaning |
|---|---|---|
| `bars` | `20` | Wave control points (resolution of the curve) |
| `framerate` | `30` | cava analysis rate |
| `waveHeight` | `200` | Surface height in px |
| `audioMethod` | `"pulse"` | cava input: `pulse` (PipeWire) or `alsa` |
| `colorPrimary` / `colorSecondary` / `colorSurface` / `colorSurfaceDim` | Catppuccin-ish | Gradient stops |
| `syncColors` | `false` | Watch a palette file and recolor live |

Restart quickshell after editing (`pkill quickshell && qs -c quickSoundWave &`,
or relaunch your session autostart command).

### Optional: match the wave to your Noctalia palette

Noctalia ships a template processor that regenerates files on every palette
change. quickSoundWave watches one such file, so the wave recolors live — no
restart anywhere. No extra script needed:

1. Copy the template input into place:

   ```sh
   mkdir -p ~/.config/noctalia/templates
   cp examples/noctalia-template.js ~/.config/noctalia/templates/quickSoundWave-colors.js
   ```

2. Register it in `~/.config/noctalia/theme.toml`:

   ```toml
   [theme.templates.user.quickSoundWave-colors]
   enabled     = true
   input_path  = "$XDG_CONFIG_HOME/noctalia/templates/quickSoundWave-colors.js"
   output_path = "$XDG_CACHE_HOME/noctalia/quickSoundWave-colors.js"
   ```

3. Render it once for the current palette:

   ```sh
   noctalia msg config-reload
   noctalia msg templates-apply
   ```

4. Set `syncColors = true` in `shell.qml` and restart quickshell.


## Troubleshooting

- **Flat line, no animation** → cava gets no audio. With `audioMethod = "pulse"`,
  check `pactl info` succeeds; on a pure ALSA system set `audioMethod = "alsa"`.
- **`qs: command not found`** → some packages only ship `quickshell`; use
  `quickshell -c quickSoundWave` instead.
- **QML errors on start** → quickshell ≥ 0.2 required (`qs --version`).
- **Wave above fullscreen apps?** It uses the *Bottom* layer; if your
  compositor has a special background layer mode (niri maps layer surfaces
  normally), tune `WlrLayershell.layer` / `exclusiveZone` in `shell.qml`.
