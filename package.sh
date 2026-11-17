#!/usr/bin/env bash
# The release's files, from what android/build.sh and macos/build.sh built:
#   dist/libmpv-android-<abi>.tar.gz  the .so files for one Android ABI (libmpv, FFmpeg, libc++_shared)
#   dist/libmpv-macos.zip             libmpv.2.dylib (arm64 and x86_64)
#   dist/SHA256SUMS
set -euo pipefail
cd "$(dirname "$0")"
android="${REEL_LIBMPV_ANDROID_CACHE:-$HOME/Library/Caches/reel/libmpv-android}/libs"
macos="${REEL_LIBMPV_CACHE:-$HOME/Library/Caches/reel/libmpv-1.1.0-n9.0.2}/libmpv.2.dylib"
rm -rf dist && mkdir dist
for dir in "$android"/*/; do
  abi="$(basename "$dir")"
  ls "$dir"*.so >/dev/null 2>&1 || continue
  tar -czf "dist/libmpv-android-$abi.tar.gz" -C "$dir" $(cd "$dir" && ls *.so)
done
[ -f "$macos" ] && (cd "$(dirname "$macos")" && zip -q -j "$OLDPWD/dist/libmpv-macos.zip" libmpv.2.dylib)
(cd dist && shasum -a 256 * > SHA256SUMS)
ls -la dist && cat dist/SHA256SUMS
