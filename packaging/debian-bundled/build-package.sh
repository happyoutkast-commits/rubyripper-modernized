#!/usr/bin/env bash

# Build the self-contained Rubyripper Debian package.
#
# This script runs as root inside the disposable container created by
# build-container.sh. It deliberately installs into the final /opt path while
# Ruby and its native gems are compiled. That keeps Ruby's recorded paths
# correct without patching binaries or inventing a relocation scheme.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

PACKAGE_NAME="rubyripper-bundled"
PACKAGE_REVISION="1"
PACKAGE_ARCHITECTURE="amd64"
RUBY_VERSION="3.4.10"
RUBY_SHA256="ecee2d072a14f2d14347dd56dfd8fe5c3130abf5117bfaacbda0f4ef9cc429ec"
RUBY_URL="https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.gz"
# Ruby 3.4.10 ships this maintained Bundler release as a default gem. The
# application dependency versions still come from Gemfile.lock.
BUNDLER_VERSION="2.6.9"

INSTALL_ROOT="/opt/rubyripper"
RUNTIME_ROOT="${INSTALL_ROOT}/runtime"
APPLICATION_ROOT="${INSTALL_ROOT}/app"
OUTPUT_DIR="${RUBYRIPPER_PACKAGE_OUTPUT:-${REPOSITORY_ROOT}/dist}"
BUILD_ROOT="$(mktemp -d /tmp/rubyripper-bundled.XXXXXX)"
PACKAGE_ROOT="${BUILD_ROOT}/package-root"
CREATED_INSTALL_ROOT=false

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

clean_up() {
  # Both paths are fixed or created by mktemp. Guard them anyway because this
  # cleanup runs as root and should never be allowed to grow broader.
  if [[ "${CREATED_INSTALL_ROOT}" == true && "${INSTALL_ROOT}" == /opt/rubyripper ]]; then
    rm -rf -- "${INSTALL_ROOT}"
  fi

  if [[ "${BUILD_ROOT}" == /tmp/rubyripper-bundled.* ]]; then
    rm -rf -- "${BUILD_ROOT}"
  fi
}
trap clean_up EXIT

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is missing."
}

read_application_version() {
  sed -n "s/^[[:space:]]*VERSION = '\([^']*\)'.*/\1/p" \
    "${REPOSITORY_ROOT}/lib/rubyripper/version.rb" | head -n 1
}

verify_build_environment() {
  [[ "${EUID}" -eq 0 ]] || fail "Run this script through build-container.sh."
  [[ "$(dpkg --print-architecture)" == "${PACKAGE_ARCHITECTURE}" ]] || \
    fail "This builder currently supports amd64 only."
  [[ ! -e "${INSTALL_ROOT}" ]] || \
    fail "${INSTALL_ROOT} already exists inside the build environment."

  local command_name
  for command_name in curl dpkg-deb dpkg-shlibdeps make msgfmt readelf sha256sum strip; do
    require_command "${command_name}"
  done
}

download_ruby() {
  local archive_path="${BUILD_ROOT}/ruby-${RUBY_VERSION}.tar.gz"

  log "Downloading Ruby ${RUBY_VERSION}"
  curl --fail --location --retry 3 --output "${archive_path}" "${RUBY_URL}"

  printf '%s  %s\n' "${RUBY_SHA256}" "${archive_path}" | sha256sum --check --status || \
    fail "Ruby source checksum did not match."

  tar --extract --gzip --file "${archive_path}" --directory "${BUILD_ROOT}"
}

build_ruby() {
  local ruby_source="${BUILD_ROOT}/ruby-${RUBY_VERSION}"
  local build_jobs
  build_jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')"

  log "Building the private Ruby runtime"
  # From this point on, cleanup owns the fixed installation path even if the
  # compiler or installer exits partway through.
  CREATED_INSTALL_ROOT=true
  (
    cd "${ruby_source}"
    ./configure \
      --prefix="${RUNTIME_ROOT}" \
      --disable-install-doc \
      --disable-shared \
      --disable-yjit
    make --jobs "${build_jobs}"
    make install
  )

  "${RUNTIME_ROOT}/bin/ruby" --version
}

install_application() {
  local build_jobs
  build_jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '2')"

  log "Installing Rubyripper and its locked runtime gems"
  "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" --version

  install -d "${APPLICATION_ROOT}"
  cp -a \
    "${REPOSITORY_ROOT}/bin" \
    "${REPOSITORY_ROOT}/lib" \
    "${REPOSITORY_ROOT}/share" \
    "${APPLICATION_ROOT}/"
  install -m 644 \
    "${REPOSITORY_ROOT}/Gemfile" \
    "${REPOSITORY_ROOT}/Gemfile.lock" \
    "${REPOSITORY_ROOT}/GPL-3.txt" \
    "${APPLICATION_ROOT}/"

  (
    cd "${APPLICATION_ROOT}"
    "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" config set --local path vendor/bundle
    "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" config set --local deployment true
    "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" config set --local without development:test
    "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" install \
      --jobs "${build_jobs}" \
      --retry 3
    "${RUNTIME_ROOT}/bin/bundle" "_${BUNDLER_VERSION}_" clean --force
  )
}

remove_build_only_files() {
  log "Removing files that are not needed at runtime"

  rm -f -- "${RUNTIME_ROOT}/lib/libruby-static.a"
  rm -rf -- "${RUNTIME_ROOT}/include"

  # Gem caches contain copies of archives that are already installed. Removing
  # them saves space without changing the installed gem set.
  find "${RUNTIME_ROOT}" "${APPLICATION_ROOT}/vendor" \
    -type d -name cache -prune -exec rm -rf -- {} +

  # Strip only real ELF objects. Scripts and data files are left untouched.
  while IFS= read -r -d '' candidate; do
    if readelf --file-header "${candidate}" >/dev/null 2>&1; then
      strip --strip-unneeded "${candidate}"
    fi
  done < <(find "${INSTALL_ROOT}" -type f -print0)
}

copy_package_files() {
  log "Assembling the Debian package filesystem"

  install -d \
    "${PACKAGE_ROOT}/DEBIAN" \
    "${PACKAGE_ROOT}/opt" \
    "${PACKAGE_ROOT}/usr/bin" \
    "${PACKAGE_ROOT}/usr/share/applications" \
    "${PACKAGE_ROOT}/usr/share/doc/${PACKAGE_NAME}" \
    "${PACKAGE_ROOT}/usr/share/icons/hicolor/128x128/apps"

  cp -a "${INSTALL_ROOT}" "${PACKAGE_ROOT}/opt/"
  install -m 755 "${SCRIPT_DIR}/rrip_cli" "${PACKAGE_ROOT}/usr/bin/rrip_cli"
  install -m 755 "${SCRIPT_DIR}/rrip_gui" "${PACKAGE_ROOT}/usr/bin/rrip_gui"
  install -m 644 \
    "${REPOSITORY_ROOT}/share/applications/rubyripper.desktop" \
    "${PACKAGE_ROOT}/usr/share/applications/rubyripper.desktop"
  install -m 644 \
    "${REPOSITORY_ROOT}/share/icons/hicolor/128x128/apps/rubyripper.png" \
    "${PACKAGE_ROOT}/usr/share/icons/hicolor/128x128/apps/rubyripper.png"
  install -m 644 \
    "${REPOSITORY_ROOT}/README.md" \
    "${PACKAGE_ROOT}/usr/share/doc/${PACKAGE_NAME}/README.md"
  install -m 644 \
    "${REPOSITORY_ROOT}/CHANGELOG" \
    "${PACKAGE_ROOT}/usr/share/doc/${PACKAGE_NAME}/CHANGELOG"
  install -m 644 \
    "${SCRIPT_DIR}/copyright" \
    "${PACKAGE_ROOT}/usr/share/doc/${PACKAGE_NAME}/copyright"

  compile_translations
}

compile_translations() {
  local po_file language locale_dir

  for po_file in "${REPOSITORY_ROOT}"/po/*/rubyripper.po; do
    language="$(basename "$(dirname "${po_file}")")"
    locale_dir="${PACKAGE_ROOT}/usr/share/locale/${language}/LC_MESSAGES"
    install -d "${locale_dir}"
    msgfmt --check-format --output-file "${locale_dir}/rubyripper.mo" "${po_file}"
  done
}

collect_shared_library_dependencies() {
  local candidate dependency_output
  local -a dependency_arguments=()

  while IFS= read -r -d '' candidate; do
    if readelf --file-header "${candidate}" >/dev/null 2>&1; then
      dependency_arguments+=("-e${candidate}")
    fi
  done < <(find "${PACKAGE_ROOT}/opt/rubyripper" -type f -print0)

  [[ "${#dependency_arguments[@]}" -gt 0 ]] || fail "No ELF runtime files were found."

  # dpkg-shlibdeps expects Debian source metadata in its working directory.
  # The build-only control file gives it that context; it is not packaged.
  install -d "${BUILD_ROOT}/debian"
  install -m 644 "${SCRIPT_DIR}/control.build" "${BUILD_ROOT}/debian/control"

  dependency_output="$(
    cd "${BUILD_ROOT}"
    dpkg-shlibdeps -O "${dependency_arguments[@]}"
  )"

  dependency_output="${dependency_output#shlibs:Depends=}"
  [[ -n "${dependency_output}" ]] || fail "Shared-library dependency detection returned nothing."
  printf '%s\n' "${dependency_output}"
}

write_control_metadata() {
  local application_version package_version installed_size shared_dependencies

  application_version="$(read_application_version)"
  [[ -n "${application_version}" ]] || fail "Could not read the Rubyripper version."
  package_version="${application_version}-${PACKAGE_REVISION}"
  installed_size="$(du --summarize --kilobytes "${PACKAGE_ROOT}" | cut -f 1)"
  shared_dependencies="$(collect_shared_library_dependencies)"

  sed \
    -e "s|@PACKAGE_VERSION@|${package_version}|g" \
    -e "s|@PACKAGE_ARCHITECTURE@|${PACKAGE_ARCHITECTURE}|g" \
    -e "s|@INSTALLED_SIZE@|${installed_size}|g" \
    -e "s|@SHARED_LIBRARY_DEPENDS@|${shared_dependencies}|g" \
    "${SCRIPT_DIR}/control.template" > "${PACKAGE_ROOT}/DEBIAN/control"
}

write_file_checksums() {
  (
    cd "${PACKAGE_ROOT}"
    find . -type f ! -path './DEBIAN/*' -print0 \
      | sort --zero-terminated \
      | xargs --null md5sum \
      | sed 's|  \./|  |'
  ) > "${PACKAGE_ROOT}/DEBIAN/md5sums"
}

build_debian_archive() {
  local application_version package_version package_path

  application_version="$(read_application_version)"
  package_version="${application_version}-${PACKAGE_REVISION}"
  package_path="${OUTPUT_DIR}/${PACKAGE_NAME}_${package_version}_${PACKAGE_ARCHITECTURE}.deb"

  log "Creating ${PACKAGE_NAME}_${package_version}_${PACKAGE_ARCHITECTURE}.deb"
  install -d "${OUTPUT_DIR}"
  dpkg-deb --root-owner-group --build "${PACKAGE_ROOT}" "${package_path}"
  dpkg-deb --info "${package_path}"

  if [[ -n "${RUBYRIPPER_OUTPUT_OWNER_UID:-}" && -n "${RUBYRIPPER_OUTPUT_OWNER_GID:-}" ]]; then
    chown "${RUBYRIPPER_OUTPUT_OWNER_UID}:${RUBYRIPPER_OUTPUT_OWNER_GID}" "${package_path}"
  fi

  printf '\nPackage written to %s\n' "${package_path}"
}

verify_build_environment
download_ruby
build_ruby
install_application
remove_build_only_files
copy_package_files
write_control_metadata
write_file_checksums
build_debian_archive
