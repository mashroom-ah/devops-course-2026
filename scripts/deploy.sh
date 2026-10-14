#!/usr/bin/env bash

# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops"
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="$(git rev-parse --show-toplevel)/site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
    echo "Неизвестный аргумент: $1" >&2
    echo "Использование: $0 [--dry-run]" >&2
    exit 1
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}/index.html" ]]; then
    echo "Ошибка: файл ${LOCAL_DIR}/index.html не найден" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения" >&2
    git status --short >&2
    exit 1
fi

# 3. Синхронизация каталога ${LOCAL_DIR} на ${REMOTE}:${REMOTE_DIR}
RSYNC_OPTS=(-avz --delete --chmod=D755,F644)
SSH_OPTS="ssh -o BatchMode=yes -o ConnectTimeout=5"

if [[ ${DRY_RUN} -eq 1 ]]; then
    RSYNC_OPTS+=(--dry-run)
fi

# 4. При --dry-run — завершение с кодом 0 без проверки доступности
rsync "${RSYNC_OPTS[@]}" -e "${SSH_OPTS}" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "[dry-run] План операций выведен, изменения не применены"
    exit 0
fi

# 5. Проверка доступности ${SITE_URL} и завершение с корректным кодом возврата
if ! curl -fsS --cacert "${CA_CERT}" -o /dev/null "${SITE_URL}"; then
    echo "Ошибка: ресурс ${SITE_URL} недоступен" >&2
    exit 1
fi

SHORT_SHA="$(git rev-parse --short HEAD)"
echo "Деплой выполнен успешно. Коммит: ${SHORT_SHA}"
exit 0