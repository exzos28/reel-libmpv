#!/usr/bin/env bash
# libmpv for Windows: not built here. zhongfly/mpv-winbuild publishes an LGPL libmpv
# (mpv-dev-lgpl-*.7z: mpv-winbuild-cmake with its compile-lgpl-libmpv.patch, which drops
# --enable-gpl and the GPL libraries from FFmpeg and builds mpv with -Dgpl=false); this takes
# its libmpv-2.dll for x86_64 and aarch64, checks what it says about itself, and puts it in the
# cache for package.sh. The sources are those of that build: see its release and
# https://github.com/zhongfly/mpv-winbuild.
#
#   windows/fetch.sh
set -euo pipefail

BUILD="2026-11-17-f92afa75cd"   # zhongfly/mpv-winbuild release
CACHE="${REEL_LIBMPV_WINDOWS_CACHE:-$HOME/Library/Caches/reel/libmpv-windows}"
mkdir -p "$CACHE" && cd "$CACHE"
for arch in x86_64 aarch64; do
  pattern="mpv-dev-lgpl-$arch-*-git-${BUILD##*-}.7z"
  ls $pattern >/dev/null 2>&1 || gh release download "$BUILD" -R zhongfly/mpv-winbuild -p "$pattern" -D .
done
docker run --rm -v "$CACHE:/w" alpine sh -euc '
  apk add -q 7zip binutils >/dev/null
  cd /w
  for arch in x86_64 aarch64; do
    rm -rf "$arch" && mkdir "$arch" && 7z x -y -o"$arch" mpv-dev-lgpl-$arch-*.7z >/dev/null
    strings -n 6 "$arch/libmpv-2.dll" | grep -m1 -E "^-Dprefix" | tr " " "\n" | grep -qx -- "-Dgpl=false" \
      || { echo "$arch: mpv not built with -Dgpl=false" >&2; exit 1; }
    echo "$arch: libmpv-2.dll, mpv -Dgpl=false"
  done'
