#!/usr/bin/env bash
# Runs Tide's headless tests: Shady's compositor side of Tide, with
# shady-shell and the shell side kept here (rices/tide).
#
#   SHADY_CHECKOUT   a built Shady checkout (default ../shady); its build
#                    directory is $SHADY_BUILD (default build), with the
#                    test clients: ninja headless-automation-probe ime-probe
#   SHADY_SHELL_BIN  shady-shell (default ../shady-shell/build/shady-shell,
#                    else the one on PATH)
#
#   tests/run.sh                 every test
#   tests/run.sh tide-layers     the ones named (tests/headless-<name>.sh)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
SHADY_CHECKOUT="$(cd "${SHADY_CHECKOUT:-$ROOT/../shady}" && pwd)"
shady_build="$SHADY_CHECKOUT/${SHADY_BUILD:-build}"
if [[ -z "${SHADY_SHELL_BIN:-}" ]]; then
    if [[ -x "$ROOT/../shady-shell/build/shady-shell" ]]; then
        SHADY_SHELL_BIN="$(cd "$ROOT/../shady-shell/build" && pwd)/shady-shell"
    else
        SHADY_SHELL_BIN="$(command -v shady-shell || true)"
    fi
fi
[[ -x "$SHADY_SHELL_BIN" ]] || { echo "run: no shady-shell (set SHADY_SHELL_BIN)" >&2; exit 2; }

# One directory with everything the tests run, as they expect.
BUILD_DIR=build-tests
mkdir -p "$BUILD_DIR"
for bin in shady shadyctl shady-rice headless-automation-probe ime-probe; do
    [[ -e "$shady_build/$bin" ]] || { echo "run: no $shady_build/$bin" >&2; exit 2; }
    ln -sfn "$shady_build/$bin" "$BUILD_DIR/$bin"
done
ln -sfn "$SHADY_SHELL_BIN" "$BUILD_DIR/shady-shell"
export SHADY_SHELL_BIN SHADY_CHECKOUT
# Tide is found in two parts: Shady's (through SHADY_ROOT) and this one.
export SHADY_RICE_PATH="$ROOT/rices"

if [[ $# -gt 0 ]]; then
    tests=()
    for name in "$@"; do tests+=("tests/headless-$name.sh"); done
else
    tests=(tests/headless-*.sh)
fi
failed=()
for test in "${tests[@]}"; do
    printf '%-32s ' "$(basename "$test" .sh)"
    if out="$(SHADY_SPATIAL_TEST_BUILD_DIR="$BUILD_DIR" bash "$test" 2>&1)"; then
        echo ok
    else
        echo FAIL
        printf '%s\n' "$out" | tail -20 | sed 's/^/    /'
        failed+=("$test")
    fi
done
[[ ${#failed[@]} -eq 0 ]] || { echo "${#failed[@]} failed: ${failed[*]}" >&2; exit 1; }
