# Rubyripper Modernized

[![CI](https://github.com/happyoutkast-commits/rubyripper-modernized/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/happyoutkast-commits/rubyripper-modernized/actions/workflows/ci.yml)

Rubyripper is a secure audio CD ripper for Linux. It reads tracks multiple
times with `cdparanoia`, compares the results, and reports sectors that could
not be verified. It provides both a GTK3 interface and a command-line
interface.

This repository continues the work of
[bleskodev/rubyripper](https://github.com/bleskodev/rubyripper) while
preserving the original project history, tags, and copyright notices. Version
0.9.0 updated Rubyripper for current Ruby releases and modern Linux systems.
Version 0.9.1 fixes incorrect correction details in ripping logs. Version
0.9.2 repairs secure-rip sector comparison, correction timing, and trial limits.

## Features

- secure multi-pass ripping with correction reporting
- GTK3 and command-line interfaces
- MusicBrainz and GnuDB metadata lookup with visible fallback reporting
- FLAC, Vorbis, MP3, WAV, Opus, WavPack, AAC, and custom codec support
- playlists, logs, ReplayGain, normalization, drive offsets, and cuesheets
- per-file collision handling without deleting an existing album folder
- desktop integration for opening logs and completed output folders
- RSpec and Cucumber test suites
- CI for Ruby 3.2 through 4.0, including the Ubuntu and Linux Mint package
  baseline

The 0.9 series has been tested on Debian with Ruby 3.3.8, Linux Mint 22.2 and
22.3, and Parrot OS. The complete RSpec and Cucumber suites pass on the Debian
development checkout. Package installation and the GTK3 interface were smoke
tested on Mint and Parrot OS, including a physical-drive WAV and FLAC rip on
Parrot OS.

See the [changelog](CHANGELOG) for the complete release history.

## Install the bundled Debian package

For most people using a 64-bit Debian-family system, the bundled `.deb` is the
simplest way to install Rubyripper. It has been tested on Debian, Ubuntu, Linux
Mint, and Parrot OS. The package includes its own Ruby runtime and locked Ruby
gems without replacing or modifying the system Ruby installation.

- [Download Rubyripper 0.9.2 for amd64](https://github.com/happyoutkast-commits/rubyripper-modernized/releases/download/v0.9.2/rubyripper-bundled_0.9.2-1_amd64.deb)
- [Download the SHA-256 checksum](https://github.com/happyoutkast-commits/rubyripper-modernized/releases/download/v0.9.2/rubyripper-bundled_0.9.2-1_amd64.deb.sha256)
- [View all Rubyripper releases](https://github.com/happyoutkast-commits/rubyripper-modernized/releases)

To download, verify, and install it from a terminal:

```bash
cd /tmp
wget https://github.com/happyoutkast-commits/rubyripper-modernized/releases/download/v0.9.2/rubyripper-bundled_0.9.2-1_amd64.deb
wget https://github.com/happyoutkast-commits/rubyripper-modernized/releases/download/v0.9.2/rubyripper-bundled_0.9.2-1_amd64.deb.sha256
sha256sum --check rubyripper-bundled_0.9.2-1_amd64.deb.sha256
sudo apt update
sudo apt install ./rubyripper-bundled_0.9.2-1_amd64.deb
```

After installation, launch Rubyripper from the desktop application menu or
run `rrip_gui`. The command-line interface is available as `rrip_cli`.

The bundled package currently supports `amd64`. Users on another architecture
or a non-Debian distribution should use the
[source installation](#install-from-a-source-checkout).

## Secure ripping

Rubyripper assumes that read errors are generally inconsistent between
attempts. It reads each selected track multiple times, compares small chunks,
and performs additional reads where results disagree.

No optical-disc ripper can guarantee perfection: disc condition, drive
quality, firmware, and repeatable read errors all matter. Rubyripper records
the verification results and any remaining suspicious positions in its
ripping log so the result can be evaluated rather than silently accepted.

The required number of matches for ordinary and mismatched chunks is
configurable. Increasing those values improves confidence but also increases
drive activity and ripping time.

## Install from a source checkout

### 1. Install system dependencies

On Debian, Ubuntu, or Linux Mint:

```bash
sudo apt update
sudo apt install \
  git ruby ruby-dev bundler build-essential pkg-config \
  cdparanoia xdg-utils \
  libcairo2-dev libffi-dev libgirepository1.0-dev \
  libgtk-3-dev libpango1.0-dev
```

Install the encoders and optional tools you intend to use. The following set
supports the commonly used codecs plus disc identification, tray control,
de-emphasis, and cuesheets:

```bash
sudo apt install \
  flac lame vorbis-tools opus-tools wavpack \
  eject sox cdrdao cd-discid
```

The GTK frontend uses **GTK3**, not GTK4. The Ruby GTK3 gem is installed by
Bundler; a distribution package named `ruby-gtk3` is not required. You no
longer have to go on an archaeological expedition to find the package.

These package instructions should also apply to other Debian derivatives.
Parrot OS has been tested successfully now that the pack of wild llamas finally
finished scheduling it.

For other distributions, install the equivalent packages using your
distribution's package manager.

### 2. Clone the repository

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/happyoutkast-commits/rubyripper-modernized.git
cd rubyripper-modernized
```

### 3. Install Ruby dependencies locally

From the repository root:

```bash
bundle config set --local path vendor/bundle
bundle install
```

Bundler configuration and installed gems remain local to the checkout and are
ignored by Git. `Gemfile.lock` is committed so installations use the tested
dependency set.

### 4. Run Rubyripper

GTK3 interface:

```bash
./bin/rubyripper_gtk3
```

Command-line interface:

```bash
./bin/rubyripper_cli
```

Check the installed source version with:

```bash
./bin/rubyripper_cli -V
```

The GTK launcher automatically activates the repository's Bundler environment.
Using Bundler explicitly is also supported:

```bash
bundle exec ./bin/rubyripper_gtk3
bundle exec ./bin/rubyripper_cli
```

The GTK interface starts without scanning the drive. This gives you a chance
to review Preferences before Rubyripper reads a disc or contacts a metadata
provider. When you are ready, insert a disc and press **Scan drive**.

Run the GTK launcher from a graphical desktop session. A plain SSH session has
no display unless graphical forwarding has been configured and will produce a
`Gtk::InitError`.

## Metadata lookup

Preferences lets you choose MusicBrainz, GnuDB, or None. When a provider is
selected, Rubyripper tries it first and uses the other provider as a fallback.
The GTK interface, command-line interface, and ripping log show which provider
actually supplied the metadata, including when a fallback was used.

Selecting None prevents online metadata lookups. If metadata is disabled, or
if neither provider returns anything useful, Rubyripper uses `Unknown` and
`Track N` placeholders that can be edited before ripping. Network lookups have
time limits, so a dead provider should fall back instead of making Rubyripper
appear frozen.

## Optional tools

- `cd-discid` or `discid`: improved GnuDB disc identification
- `flac`, `oggenc`, `lame`, `opusenc`, or `wavpack`: corresponding
  codecs
- `wavegain`, `vorbisgain`, `mp3gain`, `aacgain`, or `wvgain`:
  ReplayGain
- `normalize` or `normalize-audio`: normalization
- `sox`: de-emphasis processing
- `eject`: automatic tray ejection on Linux
- `cdrdao`: advanced TOC analysis and cuesheet generation

Advanced TOC analysis can take several minutes because `cdrdao` scans for
pregaps, hidden audio, pre-emphasis, and data tracks. Disable cuesheet
generation when exact disc-layout reproduction is not needed.

## Running tests

Install the bundle, then run:

```bash
bundle exec rspec
bundle exec cucumber
```

Headless environments may skip the GUI and translation groups:

```bash
bundle config set --local without 'gui i18n'
bundle install
bundle exec rspec
bundle exec cucumber
```

To restore the complete bundle later:

```bash
bundle config unset --local without
bundle install
```

## Legacy system installation

The historical configure-based installer remains available for distributions
and package maintainers. Validation for the 0.9 series has focused on the
Bundler-based source checkout described above.

```bash
./configure --enable-lang-all --enable-gtk3 --enable-cli --prefix=/usr
make
sudo make install
```

The installed executables are named `rrip_gui` and `rrip_cli`.

To uninstall:

```bash
sudo make uninstall
```

## Troubleshooting

### Rubyripper sees the drive but cannot read the disc

Rubyripper defaults to `/dev/cdrom`, which may point to the wrong device on a
system with multiple optical drives. This is especially common in virtual
machines where a virtual CD-ROM and a passed-through USB drive are both
present.

Select the physical device directly in Preferences, usually `/dev/sr0` or
`/dev/sr1`. The available devices can be checked with:

```bash
lsblk -o NAME,TYPE,MODEL
```

### Why does the last track sometimes rip more slowly?

When a nonzero drive offset and cdparanoia's `-Z` option are both configured,
Rubyripper removes `-Z` for the last track to avoid a cdparanoia lead-out
problem.

### Why does Advanced TOC Analysis take so long?

It runs `cdrdao read-toc` to discover layout information needed for accurate
cuesheets. It does not improve ordinary single-track FLAC or WAV output.
Disable cuesheet generation if you do not need to reproduce the original disc
layout.

### Can I use another platform?

The command-line interface may work where Ruby and the required tools are
available. The 0.9 series is tested on Linux; other platforms should be treated
as unverified until exercised.

### How do I report a bug or request a feature?

Use the [issue tracker](https://github.com/happyoutkast-commits/rubyripper-modernized/issues).

## Project history

Rubyripper originated with Bouke Woudstra and was formerly hosted on Google
Code. After the original project became inactive, the BleskoDev fork restored
compatibility with newer operating systems, added GTK3, redirected FreeDB
support to GnuDB, and continued fixing reported issues.

This modernization effort builds on that work. Most of the application remains
the work of the original author and earlier maintainers, whose history and
copyright notices are retained.

## License

Rubyripper is distributed under the GNU General Public License, version 3 or
later. See [GPL-3.txt](GPL-3.txt) for the complete license.
