# Zandronum Dedicated Server (Docker)

This repository provides a Dockerized **Zandronum dedicated server** suitable for running multiplayer Doom servers in a clean, reproducible way.  
The image is designed for **headless operation**, supports bind-mounted WADs and configuration, and handles legacy runtime dependencies required by Zandronum.

---

## Features

- Runs the **Zandronum dedicated server** (`zandronum-server`)
- Automatically creates a minimal `server.ini` if none exists
- Optionally downloads and extracts WAD/PK3 archives from URLs at startup
- Automated build & push via GitHub Actions

## Docker Compose Example
```yaml
services:
  zandronum:
    image: lancommander/zandronum:3.2.1
    container_name: zandronum-server

    # Zandronum uses UDP
    ports:
      - "10666:10666/udp"

    # Bind mounts so files appear on the host
    volumes:
      - ./config:/config

    environment:
      # Optional: download mods/maps at startup
      # EXTRA_WAD_URLS: >
      #   https://example.com/maps.zip,
      #   https://example.com/gameplay.pk3

      # Optional overrides
      # SERVER_CONFIG: /config/Overlay/server.ini
      # SERVER_ARGS: '+map map01 +sv_hostname "My Zandronum Server"'

    # Ensure container restarts if the server crashes or host reboots
    restart: unless-stopped
```

---

## Directory Layout (Host)

```text
.
├── config/
│   └── server.ini
    ├── doom2.wad
    ├── gameplay.pk3
    └── maps.zip
```
Both directories **must be writable** by Docker.

---

## Configuration

If `/config/Overlay/server.ini` does not exist, the container will generate a minimal default on first startup.

An `autoexec.cfg` file can also be created for adjusting server settings.
Example:
```
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
Supported file types:

- `.wad`
- `.pk3`
- `.pk7`
- `.pke`
- `.zip`

Archives provided via `EXTRA_WAD_URLS` are extracted into `/config` before startup.

---

## Environment Variables

| Variable | Description | Default |
|--------|-------------|---------|
| `SERVER_CONFIG` | Path to the server configuration file | `/config/Overlay/server.ini` |
| `EXTRA_WAD_URLS` | URLs to download and extract into `/config` at startup | *(empty)* |
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
mkdir -p config

docker run --rm -it \
  -p 10666:10666/udp \
  -v "$(pwd)/config:/config" \
  lancommander/zandronum:3.2.1
```
### With automatic WAD downloads
docker run --rm -it \
  -p 10666:10666/udp \
  -v "$(pwd)/config:/config" \
  -e EXTRA_WAD_URLS="https://example.com/modpack.zip" \
  lancommander/zandronum:3.2.1

## Ports
- **UDP 10666** – default Zandronum server port

## License
Zandronum is distributed under its own license.
This repository contains only Docker build logic and helper scripts licensed under MIT.