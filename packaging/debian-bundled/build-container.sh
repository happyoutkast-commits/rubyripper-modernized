#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${RUBYRIPPER_PACKAGE_OUTPUT:-${REPOSITORY_ROOT}/dist}"
BUILDER_IMAGE="rubyripper-bundled-builder:ubuntu-22.04"

find_container_engine() {
  if [[ -n "${CONTAINER_ENGINE:-}" ]]; then
    command -v "${CONTAINER_ENGINE}" >/dev/null 2>&1 || {
      echo "Container engine '${CONTAINER_ENGINE}' was not found." >&2
      return 1
    }
    printf '%s\n' "${CONTAINER_ENGINE}"
    return
  fi

  for candidate in docker podman; do
    if command -v "${candidate}" >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return
    fi
  done

  echo "Install Docker or Podman before building the bundled package." >&2
  return 1
}

CONTAINER_ENGINE="$(find_container_engine)"
mkdir -p "${OUTPUT_DIR}"

echo "Building the clean Ubuntu 22.04 package environment..."
"${CONTAINER_ENGINE}" build \
  --pull \
  --tag "${BUILDER_IMAGE}" \
  --file "${SCRIPT_DIR}/Dockerfile" \
  "${SCRIPT_DIR}"

echo "Building Rubyripper inside the package environment..."
"${CONTAINER_ENGINE}" run --rm \
  --volume "${REPOSITORY_ROOT}:/source:ro" \
  --volume "${OUTPUT_DIR}:/output" \
  --env RUBYRIPPER_PACKAGE_OUTPUT=/output \
  --env RUBYRIPPER_OUTPUT_OWNER_UID="$(id -u)" \
  --env RUBYRIPPER_OUTPUT_OWNER_GID="$(id -g)" \
  "${BUILDER_IMAGE}"
