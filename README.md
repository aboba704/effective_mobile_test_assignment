# Тестовое задание Effective Mobile Junior DevOps

Написать скрипт на bash для мониторинга процесса test в среде linux.

Скрипт должен отвечать следующим требованиям:

1. Запускаться при запуске системы (предпочтительно написать юнит systemd в дополнение к скрипту)
2. Отрабатывать каждую минуту
3. Если процесс запущен, то стучаться(по https) на https://test.com/monitoring/test/api
4. Если процесс был перезапущен, писать в лог /var/log/monitoring.log (если процесс не запущен, то ничего не делать)
5. Если сервер мониторинга не доступен, так же писать в лог.

## Решение

[script.sh](script.sh):
```bash
#!/bin/bash

# Название процесса (для примера, nginx)
PROCESS_NAME="nginx"
# Файл лога
LOG_FILE="/var/log/monitoring.log"
# Сервер, куда надо постучаться
MONITOR_URL="https://test.com/monitoring/test/api"
# Файл с последним pid процесса
LAST_PID_FILE="/var/run/test_monitor.pid"

# Текущий pid процесса
CURRENT_PID=$(pidof -s "$PROCESS_NAME")

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Если процесс не запущен, выйти
if [[ -z "$CURRENT_PID" ]]; then
    exit 0
fi

# Если файл с предыдущим pid существует, считываем его
if [[ -f "$LAST_PID_FILE" ]]; then
    LAST_PID=$(cat "$LAST_PID_FILE")
else
    LAST_PID=""
fi

# Если pid изменился — логируем
if [[ "$CURRENT_PID" != "$LAST_PID" ]]; then
    log "Process $PROCESS_NAME was restarted. New PID: $CURRENT_PID"
    # Обновляем pid
    echo "$CURRENT_PID" > "$LAST_PID_FILE"
fi

# Стучимся по https
curl -s --connect-timeout 5 --max-time 10 "$MONITOR_URL" > /dev/null
if [[ $? -ne 0 ]]; then
    log "Error: $MONITOR_URL is not responding"
fi

exit 0
```

Юнит systemd [/etc/systemd/system/script.service](script.service) для запуска скрипта от root'а:
```
[Unit]
Description=Script execute

[Service]
Type=simple
ExecStart=/home/andrey704/script.sh
User=root

[Install]
WantedBy=multi-user.target
```

Юнит systemd [/etc/systemd/system/script.timer](script.timer) для автоматического запуска юнита каждую минуту:
```
[Unit]
Description=Run script every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=script.service

[Install]
WantedBy=timers.target
```

Использованные команды терминала:
```
$ sudo touch /var/log/monitoring.log
$ sudo systemctl start nginx
$ sudo systemctl enable --now script.timer
$ cat /var/log/monitoring.log
```
