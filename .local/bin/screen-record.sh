#!/bin/bash

RECORDINGS_DIR="$HOME/Videos"
PIDFILE="/tmp/screen-record.pid"
FILEINFO="/tmp/screen-record-file.txt"

start_recording() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Already recording"
        exit 1
    fi

    # Use slurp to select region
    GEOMETRY=$(slurp 2>/dev/null)

    # Check if user cancelled selection
    if [ -z "$GEOMETRY" ]; then
        notify-send "Recording cancelled" "No region selected"
        exit 0
    fi

    FILENAME="$RECORDINGS_DIR/recording-$(date +%Y%m%d-%H%M%S).mp4"

    # Record using wf-recorder with selected geometry and audio
    wf-recorder -g "$GEOMETRY" -a -f "$FILENAME" &

    # Store the actual PID and filename
    echo $! > "$PIDFILE"
    echo "$FILENAME" > "$FILEINFO"

    notify-send "Recording started" "Region: $GEOMETRY\nSaving to $(basename "$FILENAME")"
}

stop_recording() {
    if [ ! -f "$PIDFILE" ]; then
        notify-send "No recording to save"
        exit 1
    fi

    PID=$(cat "$PIDFILE")
    FILE=$(cat "$FILEINFO")

    # Send SIGINT to the specific process
    kill -INT "$PID" 2>/dev/null

    # Clean up temp files
    rm -f "$PIDFILE" "$FILEINFO"

    # Wait for file to be finalized
    sleep 1.5

    if [ -f "$FILE" ] && [ -s "$FILE" ]; then
        echo "$FILE" | tr -d '\n' | wl-copy
        notify-send "Recording saved" "$(basename "$FILE")\nPath copied to clipboard"
    else
        notify-send "Recording failed" "File not found or empty"
    fi
}

case "$1" in
    start)
        start_recording
        ;;
    stop)
        stop_recording
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac
