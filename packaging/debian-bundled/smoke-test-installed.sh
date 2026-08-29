#!/usr/bin/env bash

# Run after the package has been installed in a clean Debian-family system.
# The GUI check succeeds only if the window stays alive under a virtual display;
# an immediate Ruby, Bundler, GTK, or gem-loading failure is treated as a bug.

set -euo pipefail

EXPECTED_VERSION="0.9.2"
RUNTIME_ROOT="/opt/rubyripper/runtime"
APPLICATION_ROOT="/opt/rubyripper/app"

command -v rrip_cli >/dev/null
command -v rrip_gui >/dev/null

"${RUNTIME_ROOT}/bin/ruby" --version | grep --fixed-strings "ruby 3.4.10"
rrip_cli --version | grep --fixed-strings "Rubyripper version ${EXPECTED_VERSION}"

export BUNDLE_GEMFILE="${APPLICATION_ROOT}/Gemfile"
export BUNDLE_FROZEN=true
export BUNDLE_WITHOUT=development:test
export BUNDLE_DISABLE_SHARED_GEMS=true
export GETTEXT_PATH=/usr/share/locale

"${RUNTIME_ROOT}/bin/bundle" exec \
  "${RUNTIME_ROOT}/bin/ruby" \
  -e 'require "gtk3"; require "gettext"; require "rexml"; puts "Bundled gems loaded"'

gui_log="$(mktemp /tmp/rubyripper-gui-smoke.XXXXXX)"
trap 'rm -f -- "${gui_log}"' EXIT

set +e
timeout 5s xvfb-run --auto-servernum rrip_gui >"${gui_log}" 2>&1
gui_status=$?
set -e

if [[ "${gui_status}" -ne 124 ]]; then
  cat "${gui_log}" >&2
  echo "The GTK frontend exited before the smoke-test timeout." >&2
  exit 1
fi

echo "Bundled package smoke test passed."
