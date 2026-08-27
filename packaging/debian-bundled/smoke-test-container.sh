#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${RUBYRIPPER_PACKAGE_OUTPUT:-${REPOSITORY_ROOT}/dist}"
TEST_IMAGE="${1:-ubuntu:22.04}"

find_container_engine() {
  if [[ -n "${CONTAINER_ENGINE:-}" ]]; then
    command -v "${CONTAINER_ENGINE}" >/dev/null 2>&1 || return 1
    printf '%s\n' "${CONTAINER_ENGINE}"
    return
  fi

  for candidate in docker podman; do
    if command -v "${candidate}" >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return
    fi
  done

  echo "Install Docker or Podman before running the package smoke test." >&2
  return 1
}

CONTAINER_ENGINE="$(find_container_engine)"
PACKAGE_PATH="$(find "${OUTPUT_DIR}" -maxdepth 1 -type f \
  -name 'rubyripper-bundled_*_amd64.deb' -print -quit)"

[[ -n "${PACKAGE_PATH}" ]] || {
  echo "No bundled package was found in ${OUTPUT_DIR}." >&2
  exit 1
}

PACKAGE_FILE="$(basename "${PACKAGE_PATH}")"

echo "Testing ${PACKAGE_FILE} in ${TEST_IMAGE}..."
"${CONTAINER_ENGINE}" run --rm \
  --volume "${REPOSITORY_ROOT}:/source:ro" \
  --volume "${OUTPUT_DIR}:/packages:ro" \
  --env DEBIAN_FRONTEND=noninteractive \
  --env PACKAGE_FILE="${PACKAGE_FILE}" \
  "${TEST_IMAGE}" \
  /source/packaging/debian-bundled/smoke-test-image.sh
