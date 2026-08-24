# Rubyripper Modernized

Rubyripper is a secure audio CD ripper for Linux. It reads tracks multiple
times with `cdparanoia`, compares the results, and reports sectors that could
not be verified. It provides both a GTK3 interface and a command-line
interface.

This repository modernizes the maintained
[bleskodev/rubyripper](https://github.com/bleskodev/rubyripper) fork while
preserving the original project history and tags.

## Current status

The modernization branch currently provides:

- Ruby 3.3 and newer dependency support through Bundler
- GTK3 and command-line interfaces
- GnuDB and MusicBrainz metadata lookup
- FLAC, Vorbis, MP3, WAV, Opus, WavPack, AAC, and custom codec support
- secure multi-pass ripping with correction reporting
- playlists, logs, ReplayGain, normalization, offsets, and optional cuesheets
- RSpec and Cucumber test suites
- CI configured for Ruby 3.3, 3.4, and 4.0

The current checkpoint was tested on Debian with Ruby 3.3.8. The complete
RSpec and Cucumber suites pass, the GTK3 interface runs from a source
checkout, and physical-drive WAV and FLAC rips have been verified. The FLAC
output decoded to PCM identical to the corresponding WAV rip.

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

On Debian or Ubuntu:

```bash
sudo apt install \
  ruby ruby-dev bundler build-essential pkg-config \
  cdparanoia \
  libcairo2-dev libffi-dev libgirepository1.0-dev \
  libgtk-3-dev libpango1.0-dev
```

Install the encoders and optional tools you intend to use. For example:

```bash
sudo apt install flac lame vorbis-tools opus-tools wavpack eject sox cdrdao
```

The GTK frontend uses **GTK3**, not GTK4. The Ruby GTK3 gem is installed by
Bundler; a distribution package named `ruby-gtk3` is not required.

### 2. Install Ruby dependencies locally

From the repository root:

```bash
bundle config set --local path vendor/bundle
bundle install
```

Bundler configuration and installed gems remain local to the checkout and are
ignored by Git. `Gemfile.lock` is committed so installations use the tested
dependency set.

### 3. Run Rubyripper

GTK3 interface:

```bash
./bin/rubyripper_gtk3
```

The source launcher automatically activates the repository's Bundler
environment. Using Bundler explicitly is also supported:

```bash
bundle exec ./bin/rubyripper_gtk3
bundle exec ./bin/rubyripper_cli
```

## Optional tools

- `cd-discid` or `discid`: improved GnuDB disc identification
- `flac`, `oggenc`, `lame`, `opusenc`, or `wavpack`: corresponding codecs
- `wavegain`, `vorbisgain`, `mp3gain`, `aacgain`, or `wvgain`: ReplayGain
- `normalize` or `normalize-audio`: normalization
- `sox`: de-emphasis processing
- `eject`: automatic tray ejection on Linux
- `cdrdao`: advanced TOC analysis and cuesheet generation

Advanced TOC analysis can take several minutes because `cdrdao` scans for
pregaps, hidden audio, pre-emphasis, and data tracks. Disable cuesheet
generation when exact disc-layout reproduction is not needed.

## Traditional system installation

The historical configure-based installer remains available:

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

## Frequently asked questions

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

The CLI may work where Ruby and the required command-line tools are available.
The current modernization checkpoint is tested on Linux; other platforms
should be treated as unverified until exercised.

### How do I report a bug or request a feature?

Use the [issue tracker](https://github.com/happyoutkast-commits/rubyripper-modernized/issues).

## Project history

Rubyripper originated with Bouke Woudstra and was formerly hosted on Google
Code. After the original project became inactive, the bleskodev fork restored
compatibility with newer operating systems, added GTK3, redirected FreeDB
support to GnuDB, and continued fixing reported issues.

This modernization effort builds on that work. Most of the application remains
the work of the original author and earlier maintainers, whose history and
copyright notices are retained.
