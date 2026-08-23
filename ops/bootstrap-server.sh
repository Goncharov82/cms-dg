#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this script as test.goncharoff.pro, not as root." >&2
  exit 77
fi

if [[ "$(id -un)" != "test.goncharoff.pro" ]]; then
  echo "Expected user test.goncharoff.pro, got $(id -un)." >&2
  exit 77
fi

if ! command -v newuidmap >/dev/null 2>&1 || ! command -v newgidmap >/dev/null 2>&1; then
  echo "Missing uidmap. An administrator must run: apt-get install -y uidmap" >&2
  exit 69
fi

if ! grep -q '^test\.goncharoff\.pro:' /etc/subuid || ! grep -q '^test\.goncharoff\.pro:' /etc/subgid; then
  echo "Missing subordinate UID/GID ranges for rootless Docker." >&2
  exit 69
fi

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [[ ! -S "${XDG_RUNTIME_DIR}/docker.sock" ]]; then
  dockerd-rootless-setuptool.sh install
fi

export DOCKER_HOST="unix://${XDG_RUNTIME_DIR}/docker.sock"
docker info >/dev/null

deploy_root="${HOME}/app"
install -d -m 700 "${deploy_root}/shared"
install -d -m 700 "${deploy_root}/backups"

if [[ ! -f "${deploy_root}/shared/.env" ]]; then
  install -m 600 /dev/null "${deploy_root}/shared/.env"
fi

echo "Rootless Docker and ${deploy_root} are ready for test.goncharoff.pro."
