FROM ubuntu:22.04

# Build on the oldest practical base we support. Binaries built here work on
# newer Debian-family systems without inheriting their newer glibc baseline.
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        binutils \
        bison \
        build-essential \
        ca-certificates \
        curl \
        dpkg-dev \
        file \
        gettext \
        libdb-dev \
        libcairo2-dev \
        libffi-dev \
        libgdbm-compat-dev \
        libgdbm-dev \
        libgirepository1.0-dev \
        libgmp-dev \
        libgtk-3-dev \
        libncurses-dev \
        libreadline-dev \
        libssl-dev \
        libyaml-dev \
        pkg-config \
        uuid-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /source

ENTRYPOINT ["/source/packaging/debian-bundled/build-package.sh"]
