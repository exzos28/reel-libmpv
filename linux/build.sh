#!/usr/bin/env bash
# libmpv for Linux, built with mpv-build (https://github.com/mpv-player/mpv-build) in Docker, as
# LGPL: FFmpeg without --enable-gpl, mpv with -Dgpl=false. FFmpeg, libass and libplacebo are
# linked statically into one libmpv.so; it needs only common system libraries (X11 or Wayland,
# EGL, ALSA or PulseAudio, FreeType, HarfBuzz, FriBidi, Fontconfig). The work tree lives in a
# Docker volume per architecture; the library comes out to $CACHE/libs/<arch>/libmpv.so.2.
#
#   linux/build.sh image <arch>   # arch: amd64 | arm64 (arm64 runs natively on Apple Silicon)
#   linux/build.sh build <arch>
#   linux/build.sh clean <arch>
set -euo pipefail

COMMIT="9443097"   # mpv-build, 2025-11-02
HERE="$(cd "$(dirname "$0")" && pwd)"
CACHE="${REEL_LIBMPV_LINUX_CACHE:-$HOME/Library/Caches/reel/libmpv-linux}"
arch="${2:?amd64 or arm64}"
IMAGE="reel-libmpv-linux:1-$arch"
VOLUME="reel-libmpv-linux-$arch"

run() {
  docker run --rm --platform "linux/$arch" -v "$VOLUME:/work" -v "$CACHE:/out" -w /work "$IMAGE" bash -euo pipefail -c "$1"
}

case "${1:-}" in
  image)
    docker build --platform "linux/$arch" -t "$IMAGE" "$HERE"
    ;;
  build)
    mkdir -p "$CACHE"
    run "
      [ -d mpv-build/.git ] || git clone -q https://github.com/mpv-player/mpv-build.git
      cd mpv-build && git fetch -q origin && git checkout -q $COMMIT
      ./use-mpv-release && ./use-ffmpeg-release && ./use-libplacebo-release
      # LGPL: no GPL parts.
      sed -i 's/--enable-gpl //' scripts/ffmpeg-config
      grep -q -- '--enable-gpl' scripts/ffmpeg-config && { echo 'still GPL'; exit 1; }
      printf '%s\n' --enable-version3 --disable-programs > ffmpeg_options
      printf '%s\n' -Dlibmpv=true -Dgpl=false -Dcplayer=false -Dvulkan=disabled -Dlua=disabled -Djavascript=disabled > mpv_options
      ./rebuild -j\$(nproc)
      mkdir -p /out/libs/$arch
      cp -L mpv/build/libmpv.so.2 /out/libs/$arch/
      strip --strip-unneeded /out/libs/$arch/libmpv.so.2
      ldd /out/libs/$arch/libmpv.so.2 | sed 's/^/  /'
    "
    ls -la "$CACHE/libs/$arch"
    ;;
  clean)
    docker volume rm "$VOLUME"
    ;;
  *) sed -n '2,12p' "$0"; exit 1 ;;
esac
