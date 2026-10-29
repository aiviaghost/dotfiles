# dotfiles

My CachyOS + Hyprland desktop, plus a step-by-step guide for turning a **fresh CachyOS install (which ships the Noctalia Hyprland dotfiles)** into this setup.

## What this setup is

A plain Hyprland desktop without a "shell" layer:

| Role | This setup | Fresh CachyOS (Noctalia) install |
| --- | --- | --- |
| Hyprland config | `~/.config/hypr/hyprland.conf` (classic hyprlang) | `~/.config/hypr/hyprland.lua` + `config/*.lua` |
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

Look: 2px border with a red/purple/orange/blue gradient, 10px rounding, gaps 5/20, blur on, Swedish (`se`) keyboard, natural touchpad scrolling, 3-finger horizontal swipe switches workspaces.

## Repo layout

```
config/                     -> mirrors ~/.config (install.sh symlinks each file)
  hypr/hyprland.conf          main Hyprland config (monitors, look, input, keybinds, rules)
  hypr/autostart.conf         waybar + polkit agent
  hypr/hyprlock.conf          lock screen
  hypr/hyprpaper.conf         wallpaper (~/Pictures/Wallpapers/flying.jpg)
  hypr/scripts/move-workspace.sh   SUPER+CTRL+N: move all windows to workspace N
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

Removing the package does **not** touch files it already copied into your home from `/etc/skel`. The most important one: **if `~/.config/hypr/hyprland.lua` exists, Hyprland loads it and ignores `hyprland.conf` completely.**

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
- `hypr/` holds the Lua config. It must go.
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

1. **Monitors** (`config/hypr/hyprland.conf`, MONITORS section). The old setup is:
   ```
   monitor=eDP-1,highres,auto,1.5                # laptop panel 2880x1620 @ 1.5x
   monitor=HDMI-A-1,5120x1440@60,auto-right,1    # 49" ultrawide
   ```
   List the new machine's outputs with `hyprctl monitors all` and adjust. A safe catch-all is to uncomment `monitor=,preferred,auto-right,1`.
2. **Battery** (`config/waybar/config.jsonc`): `"bat": "BAT0"`, `"adapter": "AC0"`. Compare with `ls /sys/class/power_supply`. On a desktop with no battery, remove `"battery"` from `modules-right`.
3. **Wifi interface**: waybar matches `wlan*`. Check `ip link`. If the device is named e.g. `wlp2s0`, change `"interface"` or remove that line.
4. **Keyboard**: `kb_layout = se`.

Validate before rebooting:

```fish
Hyprland --verify-config -c ~/.config/hypr/hyprland.conf     # should print "config ok"
ls ~/.config/hypr/                                           # must NOT contain hyprland.lua
```

### 9. Shell

CachyOS already defaults to fish. If not: `chsh -s /usr/bin/fish`. Open a new terminal; you should get the starship prompt with no fastfetch greeting.

The `config.fish` lines for conda, coursier, railway and wokwi do nothing until those tools are installed. Their installers (conda, `rustup`, `uv`, railway) add their own init lines or `conf.d/*.fish` files when you install them.

### 10. Reboot

Pick **Hyprland (uwsm)** in SDDM. You should see waybar at the top with numbered workspaces on the left and status icons on the right.

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
| `SUPER + SHIFT + left/right` | move current workspace to the other monitor |
| `SUPER + S` / `SUPER + SHIFT + S` | toggle scratchpad / move window to scratchpad |
| `SUPER + scroll` | cycle workspaces |
| `SUPER + LMB/RMB drag` | move / resize window |
| `Print` | region screenshot (hyprshot) |
| 3-finger horizontal swipe | switch workspace |

Media, volume and brightness keys work via `wpctl`, `playerctl` and `brightnessctl`.

## Troubleshooting

- **Hyprland starts with a default/example config, or ignores my changes.** `~/.config/hypr/hyprland.lua` exists. Hyprland prefers it over `hyprland.conf`, and auto-generates one if it finds no config at all. Delete it and restart Hyprland.
- **Black screen / Hyprland won't start.** Switch to a TTY (`Ctrl+Alt+F3`), run `Hyprland --verify-config -c ~/.config/hypr/hyprland.conf`, and check `journalctl --user -b -u 'wayland-wm@*'`.
- **Waybar icons show as boxes.** A Nerd Font is missing: `sudo pacman -S ttf-meslo-nerd`.
- **Qt apps complain about qt6ct.** A leftover `~/.config/uwsm/env` still sets `QT_QPA_PLATFORMTHEME=qt6ct`. Remove that line or the file, then log out and back in.
- **No password prompts from GUI apps.** `systemctl --user enable --now hyprpolkitagent.service`.

## Heads-up: hyprlang is being phased out

Hyprland 0.55 introduced Lua configs. Upstream has said the classic `hyprland.conf` (hyprlang) format will still be supported for a release or two after that, then dropped. Both machines currently run 0.56.x and `hyprland.conf` works. When an update eventually stops loading it, convert this config to `hyprland.lua` (community converters such as `hyprconf2lua` exist) and commit the result here.
