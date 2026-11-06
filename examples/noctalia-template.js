// Noctalia template INPUT for quickSoundWave colors.
// Copy this file to ~/.config/noctalia/templates/quickSoundWave-colors.js
// and register it in ~/.config/noctalia/theme.toml (see README).
// Noctalia renders the {{...}} tokens on every palette change; quickshell
// watches the rendered file and recolors the wave live.
// Required keys: primary, secondary, surface, surfaceDim.
({
    primary:    "{{colors.primary.default.hex}}",
    secondary:  "{{colors.secondary.default.hex}}",
    surface:    "{{colors.surface.default.hex}}",
    surfaceDim: "{{colors.surface_dim.default.hex}}",
})
