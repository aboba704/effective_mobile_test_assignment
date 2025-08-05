#!/bin/bash

# Название процесса
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