#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 ghcr.io/owner/image:immutable-tag" >&2
  exit 64
fi

readonly DEPLOY_ROOT="${DEPLOY_ROOT:-/opt/cms-dg}"
readonly COMPOSE_FILE="${DEPLOY_ROOT}/compose.production.yaml"
readonly ENV_FILE="${DEPLOY_ROOT}/shared/.env"
readonly BACKUP_DIR="${DEPLOY_ROOT}/backups"
readonly IMAGE="$1"
readonly CURRENT_IMAGE_FILE="${DEPLOY_ROOT}/current-image"

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Missing ${COMPOSE_FILE}" >&2
  exit 66
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}; create it from .env.production.example first." >&2
  exit 66
fi

mkdir -p "${BACKUP_DIR}"
export APP_IMAGE="${IMAGE}"
export DEPLOY_ROOT

compose() {
  docker compose --project-name cms-dg --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" "$@"
}

echo "Pulling ${IMAGE}"
compose pull app
compose up -d --wait --wait-timeout 120 postgres

if compose ps --status running --services | grep -qx postgres; then
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_path="${BACKUP_DIR}/postgres-${timestamp}.sql.gz"
  echo "Creating database backup ${backup_path}"
  compose exec -T postgres sh -c 'pg_dumpall --clean --if-exists -U "$POSTGRES_USER"' | gzip -9 > "${backup_path}"
  test -s "${backup_path}"
fi

previous_image=""
if [[ -f "${CURRENT_IMAGE_FILE}" ]]; then
  previous_image="$(<"${CURRENT_IMAGE_FILE}")"
fi

echo "Starting application"
if compose up -d --no-deps --wait --wait-timeout 180 app; then
  printf '%s\n' "${IMAGE}" > "${CURRENT_IMAGE_FILE}"
  find "${BACKUP_DIR}" -type f -name 'postgres-*.sql.gz' -mtime +30 -delete
  docker image prune -f >/dev/null
  echo "Deployment completed: ${IMAGE}"
  exit 0
fi

echo "New application failed its health check." >&2
if [[ -n "${previous_image}" && "${previous_image}" != "${IMAGE}" ]]; then
  echo "Rolling application back to ${previous_image}" >&2
  export APP_IMAGE="${previous_image}"
  compose up -d --no-deps --wait --wait-timeout 180 app || true
fi

exit 1
