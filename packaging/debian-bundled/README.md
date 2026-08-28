# Bundled Debian package

This package is for Debian-family systems that do not provide a suitable Ruby
or `ruby-gtk3` package. It carries its own Ruby runtime and the exact Ruby gems
from `Gemfile.lock`, so installing it never downloads gems and never changes the
system Ruby installation.

GTK3, glibc, and command-line audio tools remain ordinary distribution
dependencies. Bundling those would make the package much larger, interfere with
desktop themes, and create more compatibility problems than it solves.

## Compatibility target

The package is built inside Ubuntu 22.04 and currently targets `amd64`. This
gives the compiled runtime an older glibc baseline while retaining OpenSSL 3 and
a maintained GTK3 stack. The intended test range is:

- Ubuntu 22.04 and newer
- Linux Mint 21 and newer
- Debian 12 and newer
- current Debian Testing and Parrot OS

An `arm64` build can be added later without changing the package layout.

## Build

Docker or Podman is the only host build requirement:

```bash
./packaging/debian-bundled/build-container.sh
```

The builder downloads the official Ruby 3.4.10 source archive, verifies its
SHA-256 checksum, compiles it in a clean Ubuntu 22.04 container, and installs
only Rubyripper's runtime gem groups. The finished package is written to:

```text
dist/rubyripper-bundled_0.9.1-1_amd64.deb
```

The inner `build-package.sh` script writes temporarily to `/opt/rubyripper`
inside the disposable build container. Do not run that inner script directly
on a normal workstation.

## Inspect and install

```bash
dpkg-deb --info dist/rubyripper-bundled_0.9.1-1_amd64.deb
dpkg-deb --contents dist/rubyripper-bundled_0.9.1-1_amd64.deb
sudo apt install ./dist/rubyripper-bundled_0.9.1-1_amd64.deb
```

Use `apt`, not `dpkg -i`, so the normal GTK and audio-tool dependencies are
resolved automatically.

After installation, the usual commands are available:

```bash
rrip_gui
rrip_cli --version
```

## Clean-container smoke test

The smoke test installs the package in a fresh container, loads the bundled
Ruby gems, checks the CLI version, and starts the GTK window under Xvfb:

```bash
./packaging/debian-bundled/smoke-test-container.sh ubuntu:22.04
./packaging/debian-bundled/smoke-test-container.sh debian:testing-slim
```

These tests confirm startup and dependency resolution. A physical rip still
needs real hardware and remains part of release testing.
