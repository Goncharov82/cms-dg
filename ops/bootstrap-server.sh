#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 77
fi

if [[ -z "${DEPLOY_PUBLIC_KEY:-}" ]]; then
  echo "Set DEPLOY_PUBLIC_KEY to the dedicated GitHub Actions public key." >&2
  exit 64
fi

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  . /etc/os-release
  arch="$(dpkg --print-architecture)"
  printf 'Types: deb\nURIs: https://download.docker.com/linux/debian\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
    "${VERSION_CODENAME}" "${arch}" > /etc/apt/sources.list.d/docker.sources
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

if ! id deploy >/dev/null 2>&1; then
  useradd --create-home --shell /bin/bash deploy
fi

usermod -aG docker deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
authorized_keys=/home/deploy/.ssh/authorized_keys
touch "${authorized_keys}"
if ! grep -Fqx "${DEPLOY_PUBLIC_KEY}" "${authorized_keys}"; then
  printf '%s\n' "${DEPLOY_PUBLIC_KEY}" >> "${authorized_keys}"
fi
chown deploy:deploy "${authorized_keys}"
chmod 600 "${authorized_keys}"

install -d -m 755 -o deploy -g deploy /opt/cms-dg
install -d -m 700 -o deploy -g deploy /opt/cms-dg/shared
install -d -m 700 -o deploy -g deploy /opt/cms-dg/backups

if [[ ! -f /opt/cms-dg/shared/.env ]]; then
  install -m 600 -o deploy -g deploy /dev/null /opt/cms-dg/shared/.env
fi

systemctl enable --now docker

echo "Server bootstrap completed."
echo "Next: fill /opt/cms-dg/shared/.env from .env.production.example."
