#!/bin/bash
# Launch RustDesk and auto-connect with video freeze workarounds
# Fixes video freezing issues on Arrow Lake Intel GPU with Wayland

REMOTE_ID="417867964"

# Video freeze workaround environment variables
# Force X11 backend for better compatibility with Wayland
export GDK_BACKEND=x11

# Mesa settings for Intel GPU compatibility
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330

# Uncomment if video still freezes (forces software rendering):
# export LIBGL_ALWAYS_SOFTWARE=1

# RustDesk command with hardware codec disabled (main fix for Intel Arrow Lake)
RUSTDESK_CMD="rustdesk --disable-hardware-codec"

# Check if RustDesk is already running
if pgrep -x rustdesk > /dev/null; then
    # RustDesk is running, check if already connected
    if hyprctl clients -j | jq -e '.[] | select(.class == "rustdesk" and (.title | contains("Remote Desktop")))' > /dev/null; then
        # Already connected, just focus that window
        connected_window=$(hyprctl clients -j | jq -r '.[] | select(.class == "rustdesk" and (.title | contains("Remote Desktop"))) | .address' | head -1)
        hyprctl dispatch focuswindow address:$connected_window
        exit 0
    fi
    # Not connected, close existing connection windows and reconnect
    pkill -f "rustdesk.*$REMOTE_ID" 2>/dev/null
    sleep 0.3
fi

# Launch RustDesk with direct connection attempt and workarounds applied
$RUSTDESK_CMD --connect "$REMOTE_ID" > /dev/null 2>&1 &
disown