#!/bin/bash

# VAR
AUTH_LOG="/var/log/auth.log"
TELEGRAM_BOT_TOKEN="YUOR TOKEN"
TELEGRAM_CHAT_ID="YUOR CHAT ID"

# Функция для отправки сообщения в Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}"
}

# Начальный размер файла
last_size=$(stat -c%s "$AUTH_LOG")

# Основной цикл
while true; do
    # Ожидание изменения файла
    inotifywait -e modify "$AUTH_LOG" > /dev/null 2>&1

    # Текущий размер файла
    current_size=$(stat -c%s "$AUTH_LOG")

    # Если файл увеличился, проверяем новые строки
    if [ "$current_size" -gt "$last_size" ]; then
        tail -n +$((last_size+1)) "$AUTH_LOG" | while read -r line; do
            # Проверка на наличие строки, начинающейся с "Accepted password for cont"
            if [[ "$line" == *"Accepted password for cont"* ]]; then
                # Отправка сообщения в Telegram
                send_telegram_message "$line"
            fi
        done
        # Обновление последнего размера файла
        last_size=$current_size
    fi

    # Задержка перед следующей проверкой
    sleep 1
done
