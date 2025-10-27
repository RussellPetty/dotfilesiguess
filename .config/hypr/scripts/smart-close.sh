#!/bin/bash
# Smart window close - tries killactive, then force kills stubborn apps

# Get the active window class
active_class=$(hyprctl activewindow -j | jq -r '.class')

# List of apps that need force killing
force_kill_apps=("nwg-displays" "nwg-look")

# Try normal close first
hyprctl dispatch killactive

# Wait a moment and check if window still exists
sleep 0.1

# Check if the window class is in our force-kill list and still running
for app in "${force_kill_apps[@]}"; do
    if [[ "$active_class" == "$app" ]] && pgrep -x "$app" > /dev/null; then
        pkill -x "$app"
        break
    fi
done
