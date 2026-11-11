#!/usr/bin/env bash
# Regenerate Tide's screenshots: preview.jpg (the strip with a notification),
# control.jpg, launcher.jpg, overview.jpg and lock.jpg.
#
# Needs a GPU, a Shady build and shady-shell (env.sh), and checkouts of
# shady-rice-horizon and shady-rice-afterglow next to Gloam (or
# HORIZON_DIR / AFTERGLOW_DIR):
#   nix develop ../../../shady -c ./capture.sh
# foot, grim and ImageMagick come from nixpkgs. The shell runs on a private
# session bus, with Horizon's stand-ins for nmcli, wpctl and friends and its
# fixed set of applications, and Afterglow's terminal colours. (Battery and
# uptime are the machine's own.)
set -euo pipefail
source "$(dirname "$0")/env.sh"
HORIZON_DIR="${HORIZON_DIR:-$GLOAM/../shady-rice-horizon}"
AFTERGLOW_DIR="${AFTERGLOW_DIR:-$GLOAM/../shady-rice-afterglow}"
for dir in "$HORIZON_DIR/capture" "$AFTERGLOW_DIR/capture"; do
    [[ -d "$dir" ]] || { echo "capture: $dir is missing" >&2; exit 1; }
done
[[ -x "$SHADY_BUILD_DIR/shady" ]] || { echo "capture: $SHADY_BUILD_DIR/shady is missing" >&2; exit 1; }
if [[ -z "${TIDE_CAPTURE_BUS:-}" ]]; then
    exec env TIDE_CAPTURE_BUS=1 dbus-run-session -- "$0" "$@"
fi
tools() { env -u LD_LIBRARY_PATH nix shell nixpkgs#foot nixpkgs#grim nixpkgs#imagemagick -c "$@"; }
work="$(mktemp -d /tmp/tide-capture.XXXXXX)"
trap 'rm -rf "$work"' EXIT
mkdir -m 700 "$work/runtime" "$work/home"
(
    export XDG_RUNTIME_DIR="$work/runtime" HOME="$work/home" USER=you
    unset WAYLAND_DISPLAY WAYLAND_SOCKET SHADY_SOCKET
    export WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_RENDERER=gles2
    export SHADY_LUA_INIT="$RICE/capture/init.lua" CAPTURE_OUT="$work"
    export CAPTURE_FOOT_INI="$AFTERGLOW_DIR/capture/foot.ini"
    export PATH="$HORIZON_DIR/capture/bin:$PATH"
    export XDG_DATA_HOME="$work/data" XDG_DATA_DIRS="$HORIZON_DIR/capture"
    export SHADY_SHELL_CONFIG="$RICE/shell.lua"
    tools "$SHADY_BUILD_DIR/shady" -c "$TIDE_SHADY/config.lua"
) >"$work/capture.log" 2>&1 || { tail -n 40 "$work/capture.log" >&2; exit 1; }
for name in preview control launcher overview lock; do
    [[ -s "$work/$name.png" ]] || { echo "capture: $name.png is missing" >&2; tail -n 40 "$work/capture.log" >&2; exit 1; }
    tools magick "$work/$name.png" -quality 90 "$RICE/$name.jpg"
done
echo "capture: done"
