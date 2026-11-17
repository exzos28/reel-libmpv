#!/usr/bin/env bash
# libmpv for macOS, from
# MPVKit's LGPL build (https://github.com/mpvkit/MPVKit, product "MPVKit",
# not "MPVKit-GPL"). MPVKit ships static XCFrameworks; this links their macOS
# slices into one dynamic libmpv.2.dylib, so an app keeps libmpv (LGPL) replaceable.
#
#   macos/build.sh build    # downloads ~200 MB once (checksums checked), links $CACHE/libmpv.2.dylib
#
set -euo pipefail

TAG="1.1.0-n9.0.2"
CACHE="${REEL_LIBMPV_CACHE:-$HOME/Library/Caches/reel/libmpv-$TAG}"
OUT="$CACHE/libmpv.2.dylib"

build() {
  mkdir -p "$CACHE/zips" "$CACHE/xc"
  curl -fsSL "https://raw.githubusercontent.com/mpvkit/MPVKit/$TAG/Package.swift" -o "$CACHE/Package.swift"
  # The binary targets of the LGPL product: everything except *-GPL and Libsmbclient (GPL only).
  python3 -I - "$CACHE/Package.swift" > "$CACHE/targets.tsv" <<'EOF'
import re, sys
text = open(sys.argv[1]).read()
for name, url, checksum in re.findall(r'\.binaryTarget\(\s*name:\s*"([^"]+)",\s*url:\s*"([^"]+)",\s*checksum:\s*"([^"]+)"', text):
    if name.endswith("-GPL") or name == "Libsmbclient":
        continue
    print(f"{name}\t{url}\t{checksum}")
EOF
  archives=()
  while IFS=$'\t' read -r name url checksum; do
    zip="$CACHE/zips/$name.zip"
    [ -f "$zip" ] || curl -fsSL "$url" -o "$zip"
    echo "$checksum  $zip" | shasum -a 256 -c - >/dev/null
    rm -rf "$CACHE/xc/$name"
    unzip -q "$zip" -d "$CACHE/xc/$name"
    # The macOS slice: a .a, or a framework whose binary is a static archive at
    # <Name>.framework/Versions/A/<Name> (no extension, not executable).
    lib="$(find "$CACHE/xc/$name" -path '*macos-*' -type f \( -name '*.a' -o -path '*.framework/Versions/A/*' \) \
      ! -path '*/Headers/*' ! -path '*/Modules/*' ! -path '*/Resources/*' ! -name '*.plist' | head -1)"
    [ -n "$lib" ] || { echo "no macOS slice in $name" >&2; exit 1; }
    archives+=("$lib")
  done < "$CACHE/targets.tsv"

  local mpv; mpv="$(printf '%s\n' "${archives[@]}" | grep '/Libmpv' | head -1)"
  local sdk; sdk="$(xcrun --sdk macosx --show-sdk-path)"
  local others=()
  for a in "${archives[@]}"; do [ "$a" = "$mpv" ] || others+=("$a"); done
  xcrun clang -dynamiclib -arch arm64 -arch x86_64 -mmacosx-version-min=14.0 \
    -install_name @rpath/libmpv.2.dylib -o "$OUT" \
    -Wl,-force_load,"$mpv" "${others[@]}" \
    -L"$sdk/usr/lib/swift" -L"$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/macosx" \
    -framework AVFoundation -framework AudioToolbox -framework CoreAudio -framework CoreFoundation \
    -framework CoreMedia -framework CoreVideo -framework VideoToolbox -framework Metal -framework IOSurface \
    -framework OpenGL -framework QuartzCore -framework IOKit -framework Cocoa -framework Security \
    -lbz2 -liconv -lexpat -lresolv -lxml2 -lz -lc++
  echo "$OUT ($(du -h "$OUT" | cut -f1))"
}

case "${1:-}" in
  build) build ;;
  *) echo "usage: $0 build" >&2; exit 2 ;;
esac
