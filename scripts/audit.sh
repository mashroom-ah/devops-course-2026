#!/usr/bin/env bash
set -uo pipefail

PASS=0; FAIL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then
        echo " [OK]  $desc"; ((PASS++))
    else
        echo " [FAIL] $desc (ожидалось: '$expected', получено: '$actual')"; ((FAIL++))
    fi
}

echo "Аудит конфигурации: $(hostname -f), $(date '+%Y-%m-%d %H:%M')"

echo "[1] Служба SSH"
check "Вход от имени root запрещён" "no" "$(sudo sshd -T | awk '/^permitrootlogin/{print $2}')"
check "Парольная аутентификация отключена" "no" "$(sudo sshd -T | awk '/^passwordauthentication/{print $2}')"
# TODO 1: проверьте, что значение параметра port отлично от 22
check "Порт SSH отличен от 22" "2222" "$(sudo sshd -T | awk '/^port/{print $2}')"
# TODO 2: проверьте, что значение параметра maxauthtries равно 3
check "MaxAuthTries равен 3" "3" "$(sudo sshd -T | awk '/^maxauthtries/{print $2}')"

echo "[2] Межсетевой экран"
check "Межсетевой экран активен" "active" "$(sudo ufw status | awk '/^Status:/{print $2}')"
# TODO 3: проверьте, что политика по умолчанию для входящего трафика равна deny
check "Политика incoming = deny" "deny" "$(sudo ufw status verbose | awk '/Default:/{print $2}')"

echo "[3] Учётные записи"
awk -F: ' $3>=1000 && $3<65534 {printf " %s (uid=%s)\n",$1,$3}' /etc/passwd

echo "[4] Веб-сервер"
check "Синтаксис конфигурации nginx корректен" "0" "$(sudo nginx -t >/dev/null 2>&1; echo $?)"
check "Сертификат истекает не ранее чем через 30 дней" "0" \
  "$(sudo openssl x509 -in /etc/ssl/certs/devops.crt -checkend $((30*24*3600)) >/dev/null 2>&1; echo $?)"
check "Нет файлов с правом записи для всех" "" \
  "$(sudo find /var/www/devops-site -perm -o+w 2>/dev/null)"
check "Права ключа TLS равны 600" "600" \
  "$(sudo stat -c '%a' /etc/ssl/private/devops.key 2>/dev/null)"

echo "Пройдено: $PASS, не пройдено: $FAIL"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1