# Zandronum Dedicated Server (Docker)

This repository provides a Dockerized **Zandronum dedicated server** suitable for running multiplayer Doom servers in a clean, reproducible way.  
The image is designed for **headless operation**, supports bind-mounted WADs and configuration, and handles legacy runtime dependencies required by Zandronum.

---

## Features

- Runs the **Zandronum dedicated server** (`zandronum-server`)
- Supports **bind-mounted** directories for:
  - WADs / PK3s: `/wads`
  - Server configuration & persistent data: `/config`
- Automatically creates a minimal `server.ini` if none exists
- Optionally downloads and extracts WAD/PK3 archives from URLs at startup
- Compatible with legacy Zandronum dependencies:
  - SDL 1.2
  - libjpeg8 (`LIBJPEG_8.0`)
- Non-root runtime using `gosu`
- Automated build & push via GitHub Actions

## Docker Compose Example
```yaml
version: "3.9"

services:
  zandronum:
    image: zandronum-server:3.2.1
    container_name: zandronum-server

    # Zandronum uses UDP
    ports:
      - "10666:10666/udp"

    # Bind mounts so files appear on the host
    volumes:
      - ./config:/config
      - ./wads:/wads

    environment:
      # Optional: download mods/maps at startup
      # EXTRA_WAD_URLS: >
      #   https://example.com/maps.zip,
      #   https://example.com/gameplay.pk3

      # Optional overrides
      # SERVER_PORT: 10666
      # SERVER_CONFIG: /config/server.ini
      # SERVER_ARGS: '+map map01 +sv_hostname "My Zandronum Server"'

    # Ensure container restarts if the server crashes or host reboots
    restart: unless-stopped

    # Uncomment if you want the container to run as your host user
    # (recommended if you run into permission issues)
    # user: "${UID:-1000}:${GID:-1000}"
```

---

## Directory Layout (Host)

```text
.
├── config/
│   └── server.ini
└── wads/
    ├── doom2.wad
    ├── gameplay.pk3
    └── maps.zip
```
Both directories **must be writable** by Docker.

---

## Configuration

If `/config/server.ini` does not exist, the container will generate a minimal default on first startup.

Example:
```ini
set sv_hostname "My Zandronum Server"
set sv_maxclients 16
set sv_maxplayers 16
set sv_broadcast 1

set sv_coop 1
set sv_deathmatch 0
set sv_teamplay 0
```
All gameplay rules, cvars, maps, and RCON settings should live here.

## Supported Content Types

All matching files in `/wads` are automatically loaded at startup and passed to Zandronum using `-file` arguments.

Supported file types:

- `.wad`
- `.pk3`
- `.pk7`
- `.pke`
- `.zip`

Archives placed in `/wads` are loaded directly.  
Archives provided via `EXTRA_WAD_URLS` are extracted into `/wads` before startup.

---

## Environment Variables

| Variable | Description | Default |
|--------|-------------|---------|
| `SERVER_PORT` | UDP port the server listens on | `10666` |
| `SERVER_CONFIG` | Path to the server configuration file | `/config/server.ini` |
| `EXTRA_WAD_URLS` | URLs to download and extract into `/wads` at startup | *(empty)* |
| `SERVER_ARGS` | Additional Zandronum command-line arguments (advanced) | *(empty)* |

### `EXTRA_WAD_URLS`

A list of URLs separated by **commas**, **spaces**, or **newlines**.

Examples:

```bash
EXTRA_WAD_URLS="https://example.com/maps.zip,https://example.com/mod.pk3"
```
Archives are extracted into /wads. Single files are copied as-is.

---

## Running the Server
### Basic run (recommended)
```bash
mkdir -p config wads
chmod -R 777 config wads

docker run --rm -it \
  -p 10666:10666/udp \
  -v "$(pwd)/config:/config" \
  -v "$(pwd)/wads:/wads" \
  zandronum-server:3.2.1
```
### With automatic WAD downloads
docker run --rm -it \
  -p 10666:10666/udp \
  -v "$(pwd)/config:/config" \
  -v "$(pwd)/wads:/wads" \
  -e EXTRA_WAD_URLS="https://example.com/modpack.zip" \
  zandronum-server:3.2.1

## Ports
- **UDP 10666** – default Zandronum server port
(Additional ports may be used if auto-incrementing)

## License
Zandronum is distributed under its own license.
This repository contains only Docker build logic and helper scripts licensed under MIT.