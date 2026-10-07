# Конфигурация виртуальной машины devops-vm

## 1. Параметры машины
- Объём оперативной памяти: 2048 МБ
- Количество ядер процессора: 2
- Объём дискового накопителя: 25 ГБ, динамически расширяемый

## 2. Сетевые интерфейсы
| Адаптер | Тип | Адрес | Назначение |
|---|---|---|---|
| enp0s3 | NAT | 10.0.2.15/24 | Доступ в интернет (обновления пакетов) |
| enp0s8 | Host-only | 192.168.56.103/24 | Доступ с хостовой системы (SSH, будущий веб-сервер) |

## 3. Правило проброса портов
- Порт хостовой системы: 2222
- Порт гостевой системы: 2222
- Протокол: TCP
- Адаптер: 1 (NAT)

## 4. Учётные записи
| Имя | Группы | Способ аутентификации |
|---|---|---|
| student | student, sudo | пароль |
| devops | devops, sudo | SSH-ключ `~/.ssh/devops_vm` (ed25519) |

## 5. Служба SSH
- Порт: 2222
- Расположение дополняющего конфига: /etc/ssh/sshd_config.d/99-hardening.conf
- Изменённые директивы:
  - Port 2222
  - PermitRootLogin no
  - PasswordAuthentication no
  - PubkeyAuthentication yes
  - PermitEmptyPasswords no
  - MaxAuthTries 3
  - LoginGraceTime 30
  - AllowUsers devops
  - X11Forwarding no
  - ClientAliveInterval 300
  - ClientAliveCountMax 2
- ssh.socket отключён, ssh.service включён

## 6. Правила межсетевого экрана
- Политики по умолчанию: deny incoming, allow outgoing
- Правила:
  - 2222/tcp LIMIT # SSH rate-limited
  - 80/tcp ALLOW # HTTP
  - 443/tcp ALLOW # HTTPS
- Логирование: on (medium)

## 7. Снимки состояния
| Имя | Момент создания |
|---|---|
| 01-clean-install | После чистой установки Ubuntu Server 26.04.1 |
| 02-keys-configured | После настройки ключевой аутентификации |
| 03-ssh-hardened | После усиления SSH |
| 04-ufw-dns | После настройки UFW и локального домена |