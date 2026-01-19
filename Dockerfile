# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim

# ----------------------------
# Zandronum source selection
# ----------------------------
# Option A: specify version (default)
ARG ZANDRONUM_VERSION="3.2.1"
# Option B: specify an explicit archive URL (overrides version if non-empty)
ARG ZANDRONUM_URL=""

ENV ZANDRONUM_HOME=/opt/zandronum

# Runtime directories (mount these as volumes)
ENV CONFIG_DIR=/config

# Optional: comma/space/newline-separated URLs to fetch at startup into $WADS_DIR
ENV EXTRA_WAD_URLS=""

# Server settings
ENV SERVER_PORT=10666
ENV SERVER_CONFIG=/config/server.ini
ENV SERVER_ARGS=""

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

# ----------------------------
# Create a non-root user
# ----------------------------
RUN useradd -m -u 10001 -s /usr/sbin/nologin zandronum \
  && mkdir -p "${ZANDRONUM_HOME}" "${CONFIG_DIR}" \
  && chown -R zandronum:zandronum "${ZANDRONUM_HOME}" "${CONFIG_DIR}"

# ----------------------------
# Install Zandronum
# ----------------------------
RUN set -eux; \
  arch="x86_64"; \
  default_url="https://zandronum.com/downloads/zandronum${ZANDRONUM_VERSION}-linux-${arch}.tar.bz2"; \
  url="${ZANDRONUM_URL:-}"; \
  if [ -z "${url}" ]; then url="${default_url}"; fi; \
  echo "Downloading Zandronum from: ${url}"; \
  mkdir -p /tmp/zandronum; \
  curl -fsSL "${url}" -o /tmp/zandronum/zandronum.tar.bz2; \
  tar -xjf /tmp/zandronum/zandronum.tar.bz2 -C /tmp/zandronum; \
  if [ -d /tmp/zandronum/zandronum ]; then \
    cp -a /tmp/zandronum/zandronum/. "${ZANDRONUM_HOME}/"; \
  else \
    cp -a /tmp/zandronum/. "${ZANDRONUM_HOME}/"; \
  fi; \
  rm -rf /tmp/zandronum; \
  chown -R zandronum:zandronum "${ZANDRONUM_HOME}"

# ----------------------------
# Entrypoint
# ----------------------------
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME ["/config"]

EXPOSE 10666/udp

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]