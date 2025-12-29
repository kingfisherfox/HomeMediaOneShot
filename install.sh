#!/usr/bin/env bash
set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1; }

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

get_lan_ip() {
  ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n1
}

get_timezone() {
  if timedatectl show -p Timezone --value >/dev/null 2>&1; then
    timedatectl show -p Timezone --value
    return
  fi
  if need_cmd curl; then
    curl -fsS --max-time 5 https://ipapi.co/timezone | tr -d '\r' || true
  fi
}

detect_transcode_profile() {
  if [[ -e /dev/nvidia0 ]] || (need_cmd nvidia-smi && nvidia-smi >/dev/null 2>&1); then
    echo "plex_nvidia"
    return
  fi
  if [[ -e /dev/dri/renderD128 ]] || [[ -d /dev/dri ]]; then
    echo "plex_intel"
    return
  fi
  echo "plex"
}

install_docker() {
  if need_cmd docker; then
    apt_install docker-compose-plugin || true
    systemctl enable --now docker
    return
  fi

  apt_install ca-certificates curl gnupg lsb-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
}

ensure_docker_group() {
  local u="${SUDO_USER:-root}"
  groupadd -f docker
  if [[ "$u" != "root" ]]; then
    id -nG "$u" | grep -qw docker || usermod -aG docker "$u" || true
  fi
}

load_env() {
  [[ -f .env ]] || exit 1
  set -a
  source .env
  set +a
}

set_env_value() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" .env; then
    sed -i "s|^${key}=.*|${key}=${value}|" .env
  else
    printf "\n%s=%s\n" "$key" "$value" >> .env
  fi
}

fail_if_empty() {
  local key="$1"
  local value="$2"
  [[ -n "${value}" ]] || exit 1
}

write_homepage() {
  mkdir -p "${STACK_DIR}/homepage/config"
  cat > "${STACK_DIR}/homepage/config/settings.yaml" <<EOF
title: Media Stack
layout:
  Media:
    style: row
    columns: 4
  Automation:
    style: row
    columns: 4
  Management:
    style: row
    columns: 4
EOF

  cat > "${STACK_DIR}/homepage/config/services.yaml" <<EOF
- Media:
    - Plex:
        href: http://${SERVER_IP}:32400/web
- Automation:
    - Sonarr:
        href: http://${SERVER_IP}:8989
    - Radarr:
        href: http://${SERVER_IP}:7878
    - Lidarr:
        href: http://${SERVER_IP}:8686
    - Bazarr:
        href: http://${SERVER_IP}:6767
    - Overseerr:
        href: http://${SERVER_IP}:5055
    - Prowlarr:
        href: http://${SERVER_IP}:9696
- Management:
    - Homepage:
        href: http://${SERVER_IP}:3000
    - Transmission:
        href: http://${SERVER_IP}:9091
    - FlareSolverr:
        href: http://${SERVER_IP}:8191
    - LazyLibrarian:
        href: http://${SERVER_IP}:5299
    - Maintainerr:
        href: http://${SERVER_IP}:6246
EOF
}

main() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || exit 1
  grep -qi ubuntu /etc/os-release || exit 1

  apt_install ca-certificates curl gnupg lsb-release iproute2

  load_env

  if [[ "${TZ}" == "auto" || -z "${TZ}" ]]; then
    tz="$(get_timezone)"
    [[ -n "$tz" ]] && set_env_value "TZ" "$tz"
  fi

  if [[ "${SERVER_IP}" == "auto" || -z "${SERVER_IP}" ]]; then
    ip="$(get_lan_ip)"
    [[ -n "$ip" ]] && set_env_value "SERVER_IP" "$ip"
  fi

  load_env

  install_docker
  ensure_docker_group

  fail_if_empty "TRANSMISSION_RPC_PASS" "${TRANSMISSION_RPC_PASS}"
  [[ "${TRANSMISSION_RPC_PASS}" != "change_me" ]] || exit 1

  if [[ "${TRANSCODE_PROFILE}" == "auto" || -z "${TRANSCODE_PROFILE}" ]]; then
    p="$(detect_transcode_profile)"
    set_env_value "TRANSCODE_PROFILE" "$p"
  fi

  if [[ "${VPN_MODE}" == "vpn" ]]; then
    fail_if_empty "OPENVPN_USER" "${OPENVPN_USER}"
    fail_if_empty "OPENVPN_PASSWORD" "${OPENVPN_PASSWORD}"
    set_env_value "COMPOSE_PROFILES" "vpn,${TRANSCODE_PROFILE}"
  else
    set_env_value "COMPOSE_PROFILES" "novpn,${TRANSCODE_PROFILE}"
  fi

  load_env

  mkdir -p \
    "${STACK_DIR}" \
    "${CONFIG_DIR}" \
    "${DOWNLOADS_DIR}/incomplete" \
    "${DOWNLOADS_DIR}/complete" \
    "${MEDIA_DIR}/movies" \
    "${MEDIA_DIR}/tv" \
    "${MEDIA_DIR}/music" \
    "${MEDIA_DIR}/books" \
    "${MEDIA_DIR}/audiobooks"

  chown -R "${PUID}:${PGID}" "${CONFIG_DIR}" "${DOWNLOADS_DIR}" "${MEDIA_DIR}" || true

  cp ./docker-compose.yml "${STACK_DIR}/docker-compose.yml"

  write_homepage

  cd "${STACK_DIR}"
  docker compose --env-file "${OLDPWD}/.env" --profile vpn --profile novpn --profile plex --profile plex_intel --profile plex_nvidia down --remove-orphans || true
  docker compose --env-file "${OLDPWD}/.env" up -d

  echo "Homepage: http://${SERVER_IP}:3000"
  echo "Transcoding: ${TRANSCODE_PROFILE}"
  echo "VPN mode: ${VPN_MODE}"
}

main
