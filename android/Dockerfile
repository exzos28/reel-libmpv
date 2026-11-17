# The toolchain mpv-android's build scripts need (they build on Linux; the NDK's Linux host
# tools are x86_64 only, so the image is amd64). Used by android/build.sh.
FROM --platform=linux/amd64 ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      autoconf automake pkg-config libtool ninja-build gperf nasm python3-pip \
      unzip wget curl ca-certificates git python3 openjdk-17-jdk-headless make patch xz-utils bzip2 gzip zstd \
    && rm -rf /var/lib/apt/lists/* \
    # The dependencies need a newer Meson than Ubuntu's (fontconfig: >= 1.11).
    && pip install --break-system-packages --no-cache-dir "meson>=1.11"
WORKDIR /work
