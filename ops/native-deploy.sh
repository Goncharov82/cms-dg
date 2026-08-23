#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 RELEASE_ID ARCHIVE_PATH" >&2
  exit 64
fi

readonly RELEASE_ID="$1"
readonly ARCHIVE_PATH="$2"
readonly APP_ROOT="${APP_ROOT:-${HOME}/site}"
readonly RELEASES_DIR="${APP_ROOT}/releases"
readonly SHARED_DIR="${APP_ROOT}/shared"
readonly RELEASE_DIR="${RELEASES_DIR}/${RELEASE_ID}"
readonly ENV_FILE="${SHARED_DIR}/.env"
readonly BACKUP_DIR="${HOME}/app/backups"
readonly SERVICE_NAME="test-goncharoff-pro.service"
readonly HEALTH_URL="http://127.0.0.1:3090/up"

export PATH="/opt/ruby/bin:/usr/lib/postgresql/18/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/libvips/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export RAILS_ENV=production
export BUNDLE_DEPLOYMENT=true
export BUNDLE_WITHOUT="development:test"

if [[ ! -s "${ARCHIVE_PATH}" ]]; then
  echo "Release archive is missing: ${ARCHIVE_PATH}" >&2
  exit 66
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Environment file is missing: ${ENV_FILE}" >&2
  exit 66
fi

mkdir -p "${RELEASES_DIR}" "${SHARED_DIR}/storage" "${SHARED_DIR}/log" \
  "${SHARED_DIR}/tmp/pids" "${BACKUP_DIR}"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_path="${BACKUP_DIR}/native-postgres-${timestamp}.sql.gz"
echo "Creating database backup ${backup_path}"
PGPASSWORD="${DATABASE_PASSWORD}" pg_dumpall \
  --clean --if-exists \
  --host="${DATABASE_HOST:-127.0.0.1}" \
  --port="${DATABASE_PORT:-5432}" \
  --username="${DATABASE_USERNAME}" | gzip -9 > "${backup_path}"
gzip -t "${backup_path}"
chmod 600 "${backup_path}"

if [[ -e "${RELEASE_DIR}" ]]; then
  echo "Release already exists: ${RELEASE_DIR}" >&2
  exit 73
fi

mkdir -p "${RELEASE_DIR}"
tar -xzf "${ARCHIVE_PATH}" -C "${RELEASE_DIR}"

for directory in storage log tmp; do
  if [[ -e "${RELEASE_DIR}/${directory}" && ! -L "${RELEASE_DIR}/${directory}" ]]; then
    mv "${RELEASE_DIR}/${directory}" "${RELEASE_DIR}/${directory}.release"
  fi
  ln -s "${SHARED_DIR}/${directory}" "${RELEASE_DIR}/${directory}"
done

cd "${RELEASE_DIR}"
bundle config set --local path "${SHARED_DIR}/bundle"
bundle config set --local deployment true
bundle config set --local without "development:test"
bundle install --jobs 2 --retry 3
SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
bundle exec rails db:migrate

previous_release="$(readlink -f "${APP_ROOT}/current" 2>/dev/null || true)"
ln -sfn "${RELEASE_DIR}" "${APP_ROOT}/current.next"
mv -Tf "${APP_ROOT}/current.next" "${APP_ROOT}/current"

if systemctl --user restart "${SERVICE_NAME}"; then
  for attempt in $(seq 1 30); do
    if curl --fail --silent --show-error "${HEALTH_URL}" >/dev/null; then
      rm -f "${ARCHIVE_PATH}"
      find "${BACKUP_DIR}" -type f -name 'native-postgres-*.sql.gz' -mtime +30 -delete
      echo "Deployment completed: ${RELEASE_ID}"
      exit 0
    fi
    sleep 2
  done
fi

echo "Health check failed for ${RELEASE_ID}" >&2
if [[ -n "${previous_release}" && -d "${previous_release}" ]]; then
  ln -sfn "${previous_release}" "${APP_ROOT}/current.next"
  mv -Tf "${APP_ROOT}/current.next" "${APP_ROOT}/current"
  systemctl --user restart "${SERVICE_NAME}" || true
  echo "Application code rolled back to ${previous_release}" >&2
fi
exit 1
