#!/usr/bin/env bash
# libmpv for iOS and iPadOS, from MPVKit's LGPL build (https://github.com/mpvkit/MPVKit,
# product "MPVKit", not "MPVKit-GPL"), as macos/build.sh does for macOS. MPVKit ships static
# XCFrameworks; this links their iOS slices into one dynamic Libmpv.framework per slice (device,
# simulator) and wraps them in Libmpv.xcframework, so an app keeps libmpv (LGPL) replaceable.
#
#   apple/build.sh build    # downloads MPVKit's XCFrameworks once (checksums checked), makes
#                           # $CACHE/Libmpv.xcframework
#
set -euo pipefail

TAG="1.1.0-n9.0.2"
CACHE="${REEL_LIBMPV_CACHE:-$HOME/Library/Caches/reel/libmpv-$TAG}"
MIN_IOS="15.0"

fetch() {
  mkdir -p "$CACHE/zips" "$CACHE/xc"
  curl -fsSL "https://raw.githubusercontent.com/mpvkit/MPVKit/$TAG/Package.swift" -o "$CACHE/Package.swift"
  # The binary targets of the LGPL product: everything except *-GPL and Libsmbclient (GPL only).
  python3 -I - "$CACHE/Package.swift" > "$CACHE/targets.tsv" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
for name, url, checksum in re.findall(r'\.binaryTarget\(\s*name:\s*"([^"]+)",\s*url:\s*"([^"]+)",\s*checksum:\s*"([^"]+)"', text):
    if name.endswith("-GPL") or name == "Libsmbclient":
        continue
    print(f"{name}\t{url}\t{checksum}")
PY
  while IFS=$'\t' read -r name url checksum; do
    zip="$CACHE/zips/$name.zip"
    [ -f "$zip" ] || curl -fsSL "$url" -o "$zip"
    echo "$checksum  $zip" | shasum -a 256 -c - >/dev/null
    [ -d "$CACHE/xc/$name" ] || unzip -q "$zip" -d "$CACHE/xc/$name"
  done < "$CACHE/targets.tsv"
}

# The static archives of one slice ("ios-arm64", "ios-arm64_x86_64-simulator"): a .a, or a
# framework whose binary is a static archive at <Name>.framework/<Name>. A target without that
# slice (Libluajit is macOS only: MPVKit builds mpv for iOS without Lua) is left out.
archives() {
  local slice="$1"
  while IFS=$'\t' read -r name _ _; do
    lib="$(find "$CACHE/xc/$name" -path "*/$slice/*" -type f \( -name '*.a' -o -path "*.framework/*" \) \
      ! -path '*/Headers/*' ! -path '*/Modules/*' ! -path '*/Resources/*' ! -name '*.plist' ! -name '*.h' | head -1)"
    if [ -n "$lib" ]; then echo "$lib"; else echo "apple/build.sh: no $slice slice in $name, left out" >&2; fi
  done < "$CACHE/targets.tsv"
}

# Links one slice into $1/Libmpv.framework.
framework() {
  local slice="$1" sdk="$2" target="$3" out="$4"
  local all=() mpv="" others=()
  while IFS= read -r a; do all+=("$a"); done < <(archives "$slice")
  for a in "${all[@]}"; do
    case "$a" in */Libmpv.xcframework/*) mpv="$a" ;; *) others+=("$a") ;; esac
  done
  [ -n "$mpv" ] || { echo "apple/build.sh: no libmpv in $slice" >&2; exit 1; }
  local root; root="$(xcrun --sdk "$sdk" --show-sdk-path)"
  rm -rf "$out/Libmpv.framework" && mkdir -p "$out/Libmpv.framework"
  xcrun --sdk "$sdk" clang -dynamiclib -target "$target" -isysroot "$root" \
    -install_name @rpath/Libmpv.framework/Libmpv -o "$out/Libmpv.framework/Libmpv" \
    -Wl,-force_load,"$mpv" "${others[@]}" \
    -L"$root/usr/lib/swift" -L"$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$sdk" \
    -framework AVFoundation -framework AudioToolbox -framework CoreAudio -framework CoreFoundation \
    -framework CoreMedia -framework CoreVideo -framework VideoToolbox -framework Metal -framework IOSurface \
    -framework OpenGLES -framework QuartzCore -framework UIKit -framework Foundation -framework CoreText \
    -framework CoreGraphics -framework Security \
    -lbz2 -liconv -lexpat -lresolv -lxml2 -lz -lc++
  # An embedded framework needs its own Info.plist, or a device refuses to install the app.
  cat > "$out/Libmpv.framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Libmpv</string>
  <key>CFBundleIdentifier</key><string>io.mpv.libmpv</string>
  <key>CFBundleName</key><string>Libmpv</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>${TAG%%-*}</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleSupportedPlatforms</key><array><string>$([ "$sdk" = iphoneos ] && echo iPhoneOS || echo iPhoneSimulator)</string></array>
  <key>MinimumOSVersion</key><string>$MIN_IOS</string>
</dict>
</plist>
PLIST
  echo "$out/Libmpv.framework ($(du -h "$out/Libmpv.framework/Libmpv" | cut -f1))"
}

build() {
  fetch
  framework ios-arm64 iphoneos "arm64-apple-ios$MIN_IOS" "$CACHE/ios"
  framework ios-arm64_x86_64-simulator iphonesimulator "arm64-apple-ios$MIN_IOS-simulator" "$CACHE/ios-simulator"
  rm -rf "$CACHE/Libmpv.xcframework"
  xcodebuild -create-xcframework -framework "$CACHE/ios/Libmpv.framework" \
    -framework "$CACHE/ios-simulator/Libmpv.framework" -output "$CACHE/Libmpv.xcframework" >/dev/null
  echo "$CACHE/Libmpv.xcframework"
}

case "${1:-}" in
  build) build ;;
  *) echo "usage: $0 build" >&2; exit 2 ;;
esac
