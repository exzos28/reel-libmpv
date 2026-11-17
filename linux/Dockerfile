# libmpv for Linux, built with mpv-build on Ubuntu 22.04 (glibc 2.35: it loads on most current
# distributions). Used by linux/build.sh; the platform (amd64 or arm64) is the build's.
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git ca-certificates curl pkg-config nasm ninja-build python3-pip python3-jinja2 \
      autoconf automake libtool \
      libfreetype-dev libfribidi-dev libharfbuzz-dev libfontconfig1-dev \
      libx11-dev libxext-dev libxrandr-dev libxinerama-dev libxss-dev libxpresent-dev libxkbcommon-dev \
      libegl-dev libgl-dev libgbm-dev libdrm-dev libwayland-dev wayland-protocols \
      libasound2-dev libpulse-dev libva-dev libvdpau-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    # mpv and libplacebo need a newer Meson than Ubuntu 22.04's.
    && pip install --no-cache-dir "meson>=1.4"
WORKDIR /work
