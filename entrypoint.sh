#!/usr/bin/env bash
set -euo pipefail

log() { echo "[Zandronum] $*"; }

ZANDRONUM_USER="zandronum"
ZANDRONUM_HOME_DIR="/home/${ZANDRONUM_USER}"
ZANDRONUM_CONFIG_DIR="${ZANDRONUM_HOME_DIR}/.config/zandronum"

: "${CONFIG_DIR:=/config}"
: "${SERVER_PORT:=10666}"
: "${ZANDRONUM_HOME:=/opt/zandronum}"
: "${SERVER_CONFIG:=${ZANDRONUM_CONFIG_DIR}/server.ini}"
: "${SERVER_ARGS:=}"

ensure_dirs() {
  mkdir -p "${CONFIG_DIR}" "${ZANDRONUM_HOME_DIR}/.config"
}

link_config_dir() {
  if [[ -L "${ZANDRONUM_CONFIG_DIR}" ]]; then
    if [[ "$(readlink "${ZANDRONUM_CONFIG_DIR}")" != "${CONFIG_DIR}" ]]; then
      rm -f "${ZANDRONUM_CONFIG_DIR}"
      ln -s "${CONFIG_DIR}" "${ZANDRONUM_CONFIG_DIR}"
    fi
  elif [[ -e "${ZANDRONUM_CONFIG_DIR}" ]]; then
    rm -rf "${ZANDRONUM_CONFIG_DIR}"
    ln -s "${CONFIG_DIR}" "${ZANDRONUM_CONFIG_DIR}"
  else
    ln -s "${CONFIG_DIR}" "${ZANDRONUM_CONFIG_DIR}"
  fi
}

write_default_config_if_missing() {
  if [[ ! -f "${SERVER_CONFIG}" ]]; then
    log "No server.ini found; writing minimal default."
    mkdir -p "$(dirname "${SERVER_CONFIG}")"
    cat > "${SERVER_CONFIG}" << 'CFG'
////////////////////////////////////////////////////////////
// Minimal Zandronum server config
////////////////////////////////////////////////////////////

set sv_hostname "Zandronum Server"
set sv_maxclients 16
set sv_maxplayers 16
set sv_broadcast 1

set sv_coop 1
set sv_deathmatch 0
set sv_teamplay 0

// set sv_rconpassword "change-me"
CFG
  fi
}

find_zandronum_bin() {
  local candidates=(
    "${ZANDRONUM_HOME}/zandronum-server"
    "${ZANDRONUM_HOME}/zandronum_sv"
    "${ZANDRONUM_HOME}/zandronum"
    "${ZANDRONUM_HOME}/zandronum/zandronum-server"
    "${ZANDRONUM_HOME}/zandronum/zandronum_sv"
    "${ZANDRONUM_HOME}/zandronum/zandronum"
  )

  for c in "${candidates[@]}"; do
    if [[ -x "${c}" ]]; then
      echo "${c}"
      return 0
    fi
  done

  return 1
}

main() {
  ensure_dirs
  link_config_dir

  # Best-effort ownership fix for mounted volume
  chown -R "${ZANDRONUM_USER}:${ZANDRONUM_USER}" "${CONFIG_DIR}" \
    >/dev/null 2>&1 || true

  write_default_config_if_missing

  local bin
  if ! bin="$(find_zandronum_bin)"; then
    log "ERROR: Could not find Zandronum binary under ${ZANDRONUM_HOME}"
    ls -la "${ZANDRONUM_HOME}" || true
    exit 1
  fi

  log "Starting Zandronum"
  log "  Config dir:  ${ZANDRONUM_CONFIG_DIR} -> ${CONFIG_DIR}"
  log "  Config file: ${SERVER_CONFIG}"
  log "  Port (UDP):  ${SERVER_PORT}"

  exec gosu "${ZANDRONUM_USER}" \
    "${bin}" \
    -config "${SERVER_CONFIG}" \
    -port "${SERVER_PORT}" \
    ${SERVER_ARGS}
}

main "$@"
