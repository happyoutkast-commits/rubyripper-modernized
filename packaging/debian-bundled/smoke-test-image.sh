#!/usr/bin/env bash

# Prepare a fresh Debian-family container, then hand off to the checks that run
# against an installed package. Keeping this out of an inline shell string makes
# failures much easier to read and reproduce.

set -euo pipefail

: "${PACKAGE_FILE:?The package filename was not provided.}"

apt-get update
apt-get install --yes --no-install-recommends \
  xauth \
  xvfb \
  "/packages/${PACKAGE_FILE}"

/source/packaging/debian-bundled/smoke-test-installed.sh
