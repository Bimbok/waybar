# Waybar Configuration

A polished, glassy Waybar setup that stays fully Matugen-driven for colors. It uses a floating bar, pill modules, strong workspace states, and clean hover feedback while keeping the dynamic palette pipeline intact.

![Sample photo](Sample/2026-03-04-190536_hyprshot.png)

## Highlights

- Floating glass bar with subtle shadow and rounded corners.
- Matugen color integration via `colors.css` and strict token usage.
- Clear workspace states (default, hover, active, urgent).
- Clean module grouping with consistent padding and borders.
- Battery critical animation for high visibility.
- Practical click actions for Bluetooth, Wi-Fi, volume, wallpaper, and power.

## Layout Overview

- Left: Logo, Hyprland workspaces
- Center: Clock
- Right: Tray, Audio, Network, Bluetooth, Memory, Battery, Power

## Files

- `config`: Waybar module configuration and actions.
- `style.css`: Visual system (glass, pills, spacing, hover, states).
- `colors.css`: Matugen-generated palette tokens.
- `Scripts/`: Helpers for theme changes, wallpaper selection, Bluetooth, and Wi-Fi.

## Matugen Integration (Do Not Remove)

- `style.css` imports `colors.css`:
  - `@import "colors.css";`
- All colors are referenced only via Matugen tokens (e.g. `@primary`, `@background`).
- Theme updates are applied by running `matugen image` in the wallpaper scripts.

## Modules and Behavior

### `custom/logo`

- Icon: Arch logo.
- Left click: random wallpaper + Matugen regeneration.
- Right click: wallpaper picker via Rofi grid.
- Config: `config` (`custom/logo`).
- Script: `Scripts/theme-change.sh`, `Scripts/wallpaper_select.sh`.

### `hyprland/workspaces`

- Icon-only workspaces with active/urgent states.
- Persistent workspaces 1–5.
- Config: `config` (`hyprland/workspaces`).

### `clock`

- Primary format: `  %I:%M %p`.
- Alt format (tooltip): `  %a, %d %b %Y`.
- Config: `config` (`clock`).

### `tray`

- Clean system tray with spaced icons.
- Config: `config` (`tray`).

### `wireplumber`

- Shows icon + volume percent.
- Click: toggle mute (`pamixer -t`).
- Scroll: volume step 1.
- Config: `config` (`wireplumber`).

### `network`

- Wi-Fi shows signal icon; Ethernet shows wired icon.
- Left click: Wi-Fi menu via Rofi.
- Right click: external Wi-Fi script (`~/.config/rofi/wifi/wifinew.sh`).
- Config: `config` (`network`).
- Script: `Scripts/wifi.sh`.

### `bluetooth`

- Shows status or connected device name.
- Left click: Bluetooth manager menu via Rofi.
- Config: `config` (`bluetooth`).
- Script: `Scripts/bluetooth.sh`.

### `memory`

- Shows RAM usage percentage.
- Config: `config` (`memory`).

### `battery`

- Charging and discharging icon sets.
- Critical state animation.
- Config: `config` (`battery`).

### `custom/power`

- Power icon, opens `wlogout`.
- Config: `config` (`custom/power`).

## Visual System Notes

- `window#waybar` uses a translucent background and a single clean border.
- Module “pills” use `@surface_container` and `@outline_variant` for depth.
- Hover state increases contrast and raises border intensity.
- Battery critical uses pulsing glow for immediate visibility.

## Dependencies

Required or referenced by scripts/config:

- `waybar`
- `hyprland` (for workspaces module)
- `matugen` (palette generation)
- `swww` (wallpaper transitions)
- `rofi` (menus for wallpaper and Bluetooth)
- `wofi` (password entry for Wi-Fi)
- `nmcli` (NetworkManager CLI)
- `bluetoothctl`, `rfkill`
- `pamixer`
- `wlogout`
- Nerd Font with glyphs (e.g. JetBrainsMono Nerd Font)

## Usage

- Start Waybar:
  ```sh
  waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css
  ```
- Reload after edits:
  ```sh
  pkill waybar && waybar
  ```

## Customization Tips

- Module spacing and bar size: edit `spacing`, `margin-*`, and `height` in `config`.
- Per-module colors and borders: edit the corresponding selectors in `style.css`.
- Workspace icons: `hyprland/workspaces` in `config`.
- Palette: keep using Matugen; the generated colors are in `colors.css`.

## Troubleshooting

- If the bar appears without colors, confirm `style.css` still imports `colors.css`.
- If click actions do nothing, ensure scripts are executable:
  ```sh
  chmod +x ~/.config/waybar/Scripts/*.sh
  ```
- If Wi-Fi menu shows but password fails, make sure `wofi` is installed and `nmcli` is on PATH.
- If Bluetooth menu is empty, verify `bluetoothctl` and `rfkill` are installed and Bluetooth is enabled.

## Credits

- Waybar for the bar framework.
- Matugen for dynamic palettes.
