# Sourced by run.sh, run-native.sh and capture.sh: where Tide's two parts and
# the programs are.
#
#   SHADY_CHECKOUT   a built Shady checkout (default: ../shady next to Gloam),
#                    with Tide's compositor side in rices/tide and a build in
#                    $SHADY_BUILD (default build)
#   SHADY_SHELL_BIN  shady-shell (default: ../shady-shell/build/shady-shell,
#                    else the one on PATH)
RICE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOAM="$(cd "$RICE/../.." && pwd)"
SHADY_CHECKOUT="${SHADY_CHECKOUT:-$GLOAM/../shady}"
if [[ ! -f "$SHADY_CHECKOUT/rices/tide/config.lua" ]]; then
  echo "Tide: no Shady checkout at $SHADY_CHECKOUT. Set SHADY_CHECKOUT." >&2
  exit 1
fi
SHADY_CHECKOUT="$(cd "$SHADY_CHECKOUT" && pwd)"
SHADY_BUILD_DIR="$SHADY_CHECKOUT/${SHADY_BUILD:-build}"
TIDE_SHADY="$SHADY_CHECKOUT/rices/tide"
if [[ -z "${SHADY_SHELL_BIN:-}" ]]; then
  if [[ -x "$GLOAM/../shady-shell/build/shady-shell" ]]; then
    SHADY_SHELL_BIN="$(cd "$GLOAM/../shady-shell/build" && pwd)/shady-shell"
  else
    SHADY_SHELL_BIN="$(command -v shady-shell || true)"
  fi
fi
if [[ ! -x "$SHADY_SHELL_BIN" ]]; then
  echo "Tide: no shady-shell. Build ../shady-shell or set SHADY_SHELL_BIN." >&2
  exit 1
fi
export SHADY_SHELL_BIN
export SHADY_ROOT="$SHADY_CHECKOUT"
# shell.base("tide") and shady.base("tide") find both parts.
export SHADY_RICE_PATH="$GLOAM/rices"
