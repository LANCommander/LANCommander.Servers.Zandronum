# syntax=docker/dockerfile:1.7

FROM lancommander/base:latest

ENV ZANDRONUM_VERSION="3.2.1"
ENV ZANDRONUM_URL=""

# Optional: comma/space/newline-separated URLs to fetch at startup into $WADS_DIR
ENV EXTRA_WAD_URLS=""

# Server settings
ENV SERVER_ARCH="x86_64"

ENV START_EXE="zandronum-server"
ENV START_ARGS="-iwad DOOM2.WAD -config server.ini"

# ----------------------------
# Dependencies
# ----------------------------
# Install legacy libjpeg8 (provides libjpeg.so.8 with LIBJPEG_8.0)
ARG LIBJPEG8_DEB_URL="https://archive.debian.org/debian/pool/main/libj/libjpeg8/libjpeg8_8b-1_amd64.deb"

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends ca-certificates curl; \
  curl -fsSL "${LIBJPEG8_DEB_URL}" -o /tmp/libjpeg8.deb; \
  dpkg -i /tmp/libjpeg8.deb || apt-get -f install -y --no-install-recommends; \
  rm -f /tmp/libjpeg8.deb; \
  rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bzip2 \
    tar \
    unzip \
    xz-utils \
    p7zip-full \
    gosu \
    libsdl1.2debian \
    libjpeg62-turbo \
  && ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so.62 \
           /usr/lib/x86_64-linux-gnu/libjpeg.so.8 \
  && rm -rf /var/lib/apt/lists/*

RUN pwsh -Command "Install-Module PSIni -Force -Scope AllUsers"

EXPOSE 10666/udp

# COPY Modules/ "${BASE_MODULES}/"
COPY Hooks/ "${BASE_HOOKS}/"

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]