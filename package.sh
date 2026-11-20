#!/usr/bin/env bash
# The release's files, from what android/build.sh and macos/build.sh built:
#   dist/libmpv-android-<abi>.tar.gz  the .so files for one Android ABI (libmpv, FFmpeg, libc++_shared)
#   dist/libmpv-macos.zip             libmpv.2.dylib (arm64 and x86_64)
#   dist/libmpv-apple.zip             Libmpv.xcframework: iOS and iPadOS (device, simulator)
#   dist/libmpv-linux-<arch>.tar.gz   libmpv.so.2 for x86_64 or aarch64
#   dist/libmpv-windows-<arch>.zip    libmpv-2.dll for x86_64 or aarch64 (windows/fetch.sh)
#   dist/SHA256SUMS
set -euo pipefail
# The same files make the same archives (gzip -n: no timestamp). No macOS metadata in them (AppleDouble "._" files would unpack as junk elsewhere).
export COPYFILE_DISABLE=1
cd "$(dirname "$0")"
android="${REEL_LIBMPV_ANDROID_CACHE:-$HOME/Library/Caches/reel/libmpv-android}/libs"
macos="${REEL_LIBMPV_CACHE:-$HOME/Library/Caches/reel/libmpv-1.1.0-n9.0.2}/libmpv.2.dylib"
rm -rf dist && mkdir dist
for dir in "$android"/*/; do
  abi="$(basename "$dir")"
  ls "$dir"*.so >/dev/null 2>&1 || continue
  tar --no-mac-metadata -cf - -C "$dir" $(cd "$dir" && ls *.so) | gzip -n > "dist/libmpv-android-$abi.tar.gz"
done
linux="${REEL_LIBMPV_LINUX_CACHE:-$HOME/Library/Caches/reel/libmpv-linux}/libs"
for pair in amd64:x86_64 arm64:aarch64; do
  dir="$linux/${pair%%:*}"
  [ -f "$dir/libmpv.so.2" ] && tar --no-mac-metadata -cf - -C "$dir" libmpv.so.2 | gzip -n > "dist/libmpv-linux-${pair##*:}.tar.gz"
done
windows="${REEL_LIBMPV_WINDOWS_CACHE:-$HOME/Library/Caches/reel/libmpv-windows}"
for arch in x86_64 aarch64; do
  [ -f "$windows/$arch/libmpv-2.dll" ] && (cd "$windows/$arch" && zip -q -j -X "$OLDPWD/dist/libmpv-windows-$arch.zip" libmpv-2.dll)
done
[ -f "$macos" ] && (cd "$(dirname "$macos")" && zip -q -j -X "$OLDPWD/dist/libmpv-macos.zip" libmpv.2.dylib)
apple="$(dirname "$macos")/Libmpv.xcframework"
[ -d "$apple" ] && (cd "$(dirname "$apple")" && zip -q -r -X -y "$OLDPWD/dist/libmpv-apple.zip" Libmpv.xcframework)
(cd dist && shasum -a 256 * > SHA256SUMS)
ls -la dist && cat dist/SHA256SUMS
