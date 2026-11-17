# reel-libmpv

Prebuilt [libmpv](https://mpv.io) for reel's video player, built as **LGPL** (no GPL parts), with the scripts that build it. reel downloads a release's files and checks them against `SHA256SUMS`; nothing here is reel's own code.

## Releases

| File | What |
|---|---|
| `libmpv-android-arm64-v8a.tar.gz` | Android arm64: `libmpv.so`, FFmpeg's `libav*.so`, `libsw*.so`, the NDK's `libc++_shared.so` |
| `libmpv-android-armeabi-v7a.tar.gz` | The same for 32-bit ARM |
| `libmpv-macos.zip` | macOS: `libmpv.2.dylib` (arm64 and x86_64) |
| `libmpv-linux-x86_64.tar.gz`, `libmpv-linux-aarch64.tar.gz` | Linux: `libmpv.so.2` with FFmpeg, libass and libplacebo inside; built on Ubuntu 22.04 (glibc 2.35) |
| `libmpv-windows-x86_64.zip`, `libmpv-windows-aarch64.zip` | Windows: `libmpv-2.dll` (FFmpeg inside) |
| `SHA256SUMS` | Their checksums |

## What is in them

Android (built with [mpv-android](https://github.com/mpv-android/mpv-android)'s build scripts at `ebf1b3f`, NDK r30):

| Component | Version |
|---|---|
| mpv | v0.42.0-93-g3d73d07e6c (`-Dgpl=false`) |
| FFmpeg | n9.0.2 (without `--enable-gpl`; `--enable-version3`, so LGPL-3.0) |
| libass | 0.17.5-25-g21b5a54 |
| libplacebo | v7.387.0-96-g9f1fc872 |
| dav1d | 1.5.4-60-g7b4a217a |
| freetype, fribidi, harfbuzz, fontconfig, unibreak, lua, mbedTLS, libxml2, curl | as in mpv-android's `buildscripts/include/depinfo.sh` at that commit |

Linux (built with [mpv-build](https://github.com/mpv-player/mpv-build) at `9443097`): mpv v0.42.0 (`-Dgpl=false`), FFmpeg n9.0.2 (without `--enable-gpl`, `--enable-version3`), libass 0.17.5-25-g21b5a54, libplacebo v7.387.0, linked statically into one `libmpv.so.2`. It needs common system libraries only: glibc 2.35+, libstdc++, X11/xcb, EGL, ALSA, PulseAudio, VA-API, VDPAU, FreeType, HarfBuzz, FriBidi, Fontconfig, zlib.

Windows: not built here. [zhongfly/mpv-winbuild](https://github.com/zhongfly/mpv-winbuild) release `2026-11-17-f92afa75cd`, its LGPL archives (`mpv-dev-lgpl-*.7z`: mpv-winbuild-cmake with `compile-lgpl-libmpv.patch`, which drops `--enable-gpl` and the GPL libraries from FFmpeg and builds mpv with `-Dgpl=false`; mpv git f92afa75cd). `windows/fetch.sh` takes their `libmpv-2.dll` and checks it was built with `-Dgpl=false`. Its sources and build are that project's.

macOS: [MPVKit](https://github.com/mpvkit/MPVKit) `1.1.0-n9.0.2`, its LGPL product ("MPVKit", not "MPVKit-GPL"), linked into one dylib.

## Licence

libmpv and FFmpeg are under the GNU Lesser General Public License (`COPYING.LGPL-2.1`; FFmpeg's `--enable-version3` makes it LGPL-3.0). The libraries are shared libraries an app loads, so they can be replaced with your own build: the scripts below rebuild them from the sources named above. The scripts in this repository are MIT.

## Build

Android, in Docker (the NDK's Linux tools are x86_64; on Apple Silicon they run under emulation, about 15 minutes per ABI):

```
android/build.sh image
android/build.sh deps
android/build.sh build arm64
android/build.sh build armv7l
android/build.sh libs
```

Linux, in Docker (arm64 runs natively on Apple Silicon, about 2 minutes; amd64 under emulation, about 8):

```
linux/build.sh image arm64 && linux/build.sh build arm64
linux/build.sh image amd64 && linux/build.sh build amd64
```

macOS (downloads MPVKit's XCFrameworks, about 200 MB, and links them):

```
macos/build.sh build
```

Windows (downloads zhongfly's LGPL build and checks it):

```
windows/fetch.sh
```

Then `./package.sh` makes the release's files in `dist/`.
