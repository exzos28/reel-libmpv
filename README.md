# reel-libmpv

Prebuilt [libmpv](https://mpv.io) for reel's video player, built as **LGPL** (no GPL parts), with the scripts that build it. reel downloads a release's files and checks them against `SHA256SUMS`; nothing here is reel's own code.

## Releases

| File | What |
|---|---|
| `libmpv-android-arm64-v8a.tar.gz` | Android arm64: `libmpv.so`, FFmpeg's `libav*.so`, `libsw*.so`, the NDK's `libc++_shared.so` |
| `libmpv-android-armeabi-v7a.tar.gz` | The same for 32-bit ARM |
| `libmpv-macos.zip` | macOS: `libmpv.2.dylib` (arm64 and x86_64) |
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

macOS (downloads MPVKit's XCFrameworks, about 200 MB, and links them):

```
macos/build.sh build
```

Then `./package.sh` makes the release's files in `dist/`.
