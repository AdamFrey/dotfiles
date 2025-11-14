#!/bin/sh
set -e

# Setup temp directory
TMPDIR="${XDG_RUNTIME_DIR:-/tmp}/app/com.fastmail.Fastmail"
mkdir -p "$TMPDIR"

# GPU and display flags
FLAGS=""

# Check for Wayland
if [ -n "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
    # Check for NVIDIA GPU
    if [ -e /dev/nvidia0 ]; then
        FLAGS="$FLAGS --disable-gpu-sandbox"
    fi

    # Wayland-specific flags
    FLAGS="$FLAGS --enable-wayland-ime --wayland-text-input-version=3"
    FLAGS="$FLAGS --ozone-platform=wayland --enable-features=WaylandWindowDecorations"
fi

exec @electron@/bin/electron @out@/opt/fastmail/resources/app.asar $FLAGS "$@"
