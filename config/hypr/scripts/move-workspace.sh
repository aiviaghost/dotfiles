#!/usr/bin/env bash
# Move every window on the current workspace to the target workspace.
# Usage: move-workspace.sh <target-workspace-id>

target="$1"
[ -z "$target" ] && exit 1

# Current (active) workspace id
current=$(hyprctl activeworkspace -j | jq '.id')

# Nothing to do if we're already there
[ "$current" = "$target" ] && exit 0

# Move each window on the current workspace, silently (don't follow yet)
for addr in $(hyprctl clients -j \
    | jq -r --argjson ws "$current" '.[] | select(.workspace.id == $ws) | .address'); do
    hyprctl dispatch movetoworkspacesilent "$target,address:$addr"
done

# Follow the windows to their new home
hyprctl dispatch workspace "$target"
