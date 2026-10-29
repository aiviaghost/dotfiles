-- Autostart necessary processes (like notifications daemons, status bars, etc.)
hl.on("hyprland.start", function()
    hl.exec_cmd("sleep 1 && uwsm app -- waybar")
    hl.exec_cmd("systemctl --user enable --now hyprpolkitagent.service")
    -- hl.exec_cmd("systemctl --user enable --now hyprpaper.service")
    -- hl.exec_cmd("neowall") -- drains laptop battery
end)
