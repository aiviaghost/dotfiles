# dotfiles

My CachyOS + Hyprland desktop, plus a step-by-step guide for turning a **fresh CachyOS install (which ships the Noctalia Hyprland dotfiles)** into this setup.

## What this setup is

A plain Hyprland desktop without a "shell" layer:

| Role | This setup | Fresh CachyOS (Noctalia) install |
| --- | --- | --- |
| Hyprland config | `~/.config/hypr/hyprland.lua` (single file, converted from the old default config) | `~/.config/hypr/hyprland.lua` + `config/*.lua` |
| Bar / panel | **waybar** (default stylesheet) | Noctalia shell |
| App launcher | **wofi** (`wofi --show=drun`) | Noctalia launcher |
| Lock screen | **hyprlock** | Noctalia lock |
| Wallpaper | **hyprpaper** (`neowall` optional) | Noctalia |
| Polkit agent | **hyprpolkitagent** (systemd user service) | Noctalia |
| Terminal | kitty (Fira Code) | kitty (CachyOS config) |
| File manager | dolphin | dolphin |
| Screenshots | **hyprshot** (`Print` = region) | grim/slurp/swash |
| Login | **SDDM**, session "Hyprland (uwsm)" | SDDM or noctalia-greeter (greetd) |
| Shell | fish + CachyOS fish config + **starship** prompt | fish + CachyOS fish config |
| Theming | GTK/Qt defaults (Adwaita), default cursor | adw-gtk3 dark, qt6ct, Bibata cursor |

> **Requires Hyprland 0.55 or newer.** Hyprland 0.57 removed support for the old `hyprland.conf` (hyprlang) format, so the config is Lua. Tested on 0.56.2 and 0.57.0.

Look: 2px border with a red/purple/orange/blue gradient, 10px rounding, gaps 5/20, blur on, Swedish (`se`) keyboard, natural touchpad scrolling, 3-finger horizontal swipe switches workspaces.

## Repo layout

```
config/                     -> mirrors ~/.config (install.sh symlinks each file)
  hypr/hyprland.lua           main Hyprland config (monitors, look, input, keybinds, rules)
  hypr/autostart.lua          waybar + polkit agent (loaded with require("autostart"))
  hypr/hyprlock.conf          lock screen (hyprlock still uses its own .conf format)
  hypr/hyprpaper.conf         wallpaper (~/Pictures/Wallpapers/flying.jpg)
  waybar/config.jsonc         workspaces | power profile, wifi, bluetooth, audio, battery, clock
  kitty/kitty.conf            font = Fira Code
  fish/config.fish            sources CachyOS fish config, PATH tweaks, starship
  fish/cachyos-config.fish    CachyOS fish config with fastfetch greeting + eza aliases disabled
  starship.toml               prompt
  micro/                      micro editor settings + catppuccin colour schemes
  neowall/config.vibe         shader wallpaper config (optional)
  systemd/user/wayland-wm@hyprland.desktop.service.d/override.conf
                              OOMPolicy=continue, so an OOM-kill (e.g. a browser tab) doesn't log you out
  mimeapps.list               Firefox as default browser
packages/
  pacman.txt                  repo packages this desktop needs
  aur.txt                     AUR packages this desktop needs
  pacman-explicit-full.txt    every explicitly installed package on the old machine (reference only)
  aur-explicit-full.txt       every explicitly installed AUR package on the old machine (reference only)
install.sh                  symlinks config/ into ~/.config, backing up anything it replaces
                            and removing links to files that were deleted from the repo
scripts/new-feature.sh      unrelated work helper (git worktrees)
```

---

## Walkthrough: fresh CachyOS (Noctalia) -> this setup

> **Safety net:** do all of this from inside the Noctalia session in a kitty terminal, or from a TTY (`Ctrl+Alt+F3`). If Hyprland ever fails to start afterwards, log into a TTY and check `~/.config/hypr/` (see Troubleshooting).

### 1. Update the system and get the repo

```fish
sudo pacman -Syu
sudo pacman -S --needed git github-cli
gh auth login                       # optional, only needed to push changes back
git clone https://github.com/aiviaghost/dotfiles.git ~/Github/dotfiles
cd ~/Github/dotfiles
```

### 2. Install the packages this setup needs

```fish
sudo pacman -S --needed (grep -Ev '^(#|$)' packages/pacman.txt)

# Mark them as explicitly installed. Several (hyprland, kitty, dolphin, uwsm, ...)
# were pulled in as *dependencies* of the Noctalia package, so removing Noctalia
# with -Rns in step 4 would otherwise remove them too.
sudo pacman -D --asexplicit (grep -Ev '^(#|$)' packages/pacman.txt)
```

(In bash/zsh, use `$(grep -Ev '^(#|$)' packages/pacman.txt)` instead of `(...)`.)

### 3. Install an AUR helper and the AUR packages

The new installer no longer ships `paru`, but it's in the CachyOS repos:

```fish
sudo pacman -S --needed paru
paru -S --needed (grep -Ev '^(#|$)' packages/aur.txt)
```

- `nmgui-bin` opens when you click the wifi icon in waybar.
- `neowall-git` is optional (shader wallpapers, disabled by default because it drains battery).

### 4. Remove Noctalia

Preview first, and check that nothing you want is in the list:

```fish
pacman -Rns --print cachyos-hypr-noctalia noctalia
```

Then remove:

```fish
sudo pacman -Rns cachyos-hypr-noctalia noctalia
```

If `noctalia-greeter` is installed (`pacman -Q noctalia-greeter`), leave it for now. It is the login screen and gets replaced in step 7.

### 5. Clear the Noctalia user configs out of your home directory

Removing the package does **not** touch files it already copied into your home from `/etc/skel`. The most important is `~/.config/hypr/`: Noctalia's `hyprland.lua` there starts the Noctalia shell and loads its own `config/*.lua` files.

Move everything into a backup folder (nothing is deleted):

```fish
set B ~/noctalia-backup
mkdir -p $B
for p in .config/hypr .config/noctalia .config/uwsm .config/qt6ct .config/gtk-3.0 .config/gtk-4.0 \
         .config/kitty .config/swash .config/xsettingsd .config/kdeglobals .config/mimeapps.list \
         .config/btop .config/dolphinrc .icons/default
    test -e ~/$p; and mkdir -p (dirname $B/$p); and mv ~/$p $B/$p
end
```

What each one did:
- `hypr/` holds Noctalia's Hyprland config. It must go. `install.sh` puts this repo's `hyprland.lua` in its place.
- `noctalia/` holds the shell config.
- `uwsm/env` forces `QT_QPA_PLATFORMTHEME=qt6ct` and the Bibata cursor. This setup has no `uwsm/env`.
- `qt6ct`, `gtk-3.0`, `gtk-4.0`, `kdeglobals`, `xsettingsd` hold the dark adw-gtk3/Qt theming.
- `.icons/default` sets Bibata as the default cursor.
- `kitty/` and `mimeapps.list` are replaced by this repo.
- `swash`, `btop`, `dolphinrc` are harmless. Keep them if you like.

> If you *like* the dark GTK/Qt theme or the Bibata cursor, just don't move `gtk-3.0`, `gtk-4.0`, `qt6ct`, `kdeglobals` or `.icons/default`. You'd then need to keep `qt6ct` installed and recreate `~/.config/uwsm/env` with only the `QT_QPA_PLATFORMTHEME` / cursor lines. The old machine uses the plain defaults.

### 6. Install the dotfiles

```fish
./install.sh --dry-run    # see what it will do
./install.sh              # symlink config/* into ~/.config
```

Each file becomes a symlink into the repo, so later edits can be committed and pulled on the other machine. Anything already at a target path is moved to `~/.config-backup-<timestamp>/`. Use `./install.sh --copy` if you'd rather have plain copies.

Then enable the user services and pick up the systemd override:

```fish
systemctl --user daemon-reload
systemctl --user enable hyprpolkitagent.service hyprpaper.service
sudo systemctl enable --now bluetooth.service
```

Wallpaper: hyprpaper expects `~/Pictures/Wallpapers/flying.jpg` (not in the repo). Copy it over from the old machine:

```fish
mkdir -p ~/Pictures/Wallpapers
scp OLD-MACHINE:Pictures/Wallpapers/flying.jpg ~/Pictures/Wallpapers/
```

Or point `config/hypr/hyprpaper.conf` at any other image.

### 7. Login manager: SDDM with the "Hyprland (uwsm)" session

Check what's running:

```fish
systemctl status display-manager --no-pager | head -3
```

- **Already SDDM:** nothing to do.
- **greetd / noctalia-greeter:** switch to SDDM:
  ```fish
  sudo systemctl disable greetd.service
  sudo systemctl enable sddm.service
  sudo pacman -Rns noctalia-greeter      # optional
  ```

On the first login, pick **Hyprland (uwsm)** in the session dropdown. SDDM remembers it after that.

### 8. Machine-specific edits (do these before rebooting)

The configs come from a laptop with an external ultrawide, so check these:

1. **Monitors** (`config/hypr/hyprland.lua`, MONITORS section). The old setup is:
   ```lua
   hl.monitor({ output = "eDP-1",    mode = "highres",      position = "auto",       scale = 1.5 })  -- laptop panel 2880x1620 @ 1.5x
   hl.monitor({ output = "HDMI-A-1", mode = "5120x1440@60", position = "auto-right", scale = 1 })    -- 49" ultrawide
   ```
   List the new machine's outputs with `hyprctl monitors all` and adjust. A safe catch-all is to uncomment the `output = ""` fallback line.
2. **Battery** (`config/waybar/config.jsonc`): `"bat": "BAT0"`, `"adapter": "AC0"`. Compare with `ls /sys/class/power_supply`. On a desktop with no battery, remove `"battery"` from `modules-right`.
3. **Wifi interface**: waybar matches `wlan*`. Check `ip link`. If the device is named e.g. `wlp2s0`, change `"interface"` or remove that line.
4. **Keyboard**: `kb_layout = "se"` in the INPUT section.

Validate before rebooting:

```fish
Hyprland --verify-config        # should end with "config ok"
ls -l ~/.config/hypr/           # hyprland.lua and autostart.lua should be symlinks into the repo
```

It may also print `Couldn't bind the Hyprland Socket 2 ... IPC will not work`. Ignore that line: the checker starts a throwaway Hyprland that tries to open its own IPC socket, which it doesn't need for checking. Only the last line matters, and it should be `config ok`.

### 9. Shell

CachyOS already defaults to fish. If not: `chsh -s /usr/bin/fish`. Open a new terminal; you should get the starship prompt with no fastfetch greeting.

The `config.fish` lines for conda, coursier, railway and wokwi do nothing until those tools are installed. Their installers (conda, `rustup`, `uv`, railway) add their own init lines or `conf.d/*.fish` files when you install them.

### 10. Reboot

Pick **Hyprland (uwsm)** in SDDM. You should see waybar at the top with numbered workspaces on the left and status icons on the right.

### Updating a machine that already uses these dotfiles

```fish
cd ~/Github/dotfiles
git pull
./install.sh        # links new files, prunes links to removed ones
hyprctl reload      # or log out and back in
```

On the old laptop, where `~/.config/hypr/hyprland.conf` is still a plain file, do this **before** updating to Hyprland 0.57. `install.sh` adds `hyprland.lua` next to it, and Hyprland prefers the `.lua` file from 0.55 on, so the switch happens on the next login.

---

## Keybinds

`SUPER` = Windows key.

| Keys | Action |
| --- | --- |
| `SUPER + Q` | kitty |
| `SUPER + R` | app launcher (wofi) |
| `SUPER + E` | dolphin |
| `SUPER + C` | close window |
| `SUPER + M` | exit Hyprland |
| `SUPER + V` | toggle floating |
| `SUPER + F` | fullscreen |
| `SUPER + P` / `SUPER + J` | pseudotile / toggle split (dwindle) |
| `SUPER + L` | lock (hyprlock); closing the lid also locks |
| `SUPER + arrows` | move focus (and raise the window) |
| `SUPER + 1..0` | go to workspace 1..10 |
| `SUPER + SHIFT + 1..0` | move window to workspace |
| `SUPER + CTRL + 1..0` | move **all** windows on this workspace to workspace N |
| `SUPER + SHIFT + left/right` | move current workspace to the monitor on the left/right |
| `SUPER + S` / `SUPER + SHIFT + S` | toggle scratchpad / move window to scratchpad |
| `SUPER + scroll` | cycle workspaces |
| `SUPER + LMB/RMB drag` | move / resize window |
| `Print` | region screenshot (hyprshot) |
| 3-finger horizontal swipe | switch workspace |

Media, volume and brightness keys work via `wpctl`, `playerctl` and `brightnessctl`.

## Troubleshooting

- **`unexpected symbol near '#'` when validating.** Hyprland is reading a hyprlang file (`hyprland.conf`) as Lua. Since 0.57 only `hyprland.lua` is supported. Don't pass `-c ~/.config/hypr/hyprland.conf`. Pull this repo and rerun `./install.sh`.
- **Hyprland starts with a default/example config, or ignores my changes.** `~/.config/hypr/hyprland.lua` is not this repo's file. Hyprland writes an example `hyprland.lua` when it finds no Lua config. Run `./install.sh`, which backs that file up and links the real one.
- **Black screen / Hyprland won't start.** Switch to a TTY (`Ctrl+Alt+F3`), run `Hyprland --verify-config`, and check `journalctl --user -b -u 'wayland-wm@*'`.
- **Waybar icons show as boxes.** A Nerd Font is missing: `sudo pacman -S ttf-meslo-nerd`.
- **Qt apps complain about qt6ct.** A leftover `~/.config/uwsm/env` still sets `QT_QPA_PLATFORMTHEME=qt6ct`. Remove that line or the file, then log out and back in.
- **No password prompts from GUI apps.** `systemctl --user enable --now hyprpolkitagent.service`.

## Notes on the Lua config (Hyprland 0.57+)

- `hyprctl dispatch` now takes Lua, e.g. `hyprctl dispatch 'hl.dsp.focus({ workspace = 3 })'`, and `hyprctl eval '<lua>'` runs arbitrary Lua. Old-style `hyprctl dispatch workspace 3` scripts no longer work.
- `SUPER + CTRL + N` (move all windows) used to call `scripts/move-workspace.sh` (hyprctl + jq). It is now the `moveAllWindowsTo` function inside `hyprland.lua`.
- Binds that ran two dispatchers on one key (focus + raise) are now one Lua function per key.
- `SUPER + SHIFT + left/right` used to mean "next/previous monitor" (`+1`/`-1`). The Lua API takes a direction, so it now moves the workspace to the monitor physically on that side.
- hyprlock and hyprpaper still use their own `.conf` files. Only Hyprland itself moved to Lua.
- API reference: the wiki (https://wiki.hypr.land/configuring/) and the type stubs at `/usr/share/hypr/stubs/hl.meta.lua`.
