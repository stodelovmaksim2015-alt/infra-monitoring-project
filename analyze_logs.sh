
#!/usr/bin/env bash

set -euo pipefail

# Проверка количества аргументов
if (( $# > 1 )); then
    echo "Использование: $0 [путь_к_логу]" >&2
    exit 1
fi

log_file="${1:-access.log}"

# Генерация тестового лога, если аргумент не передан
# и access.log ещё не существует
if (( $# == 0 )) && [[ ! -e "$log_file" ]]; then
    for ((i = 0; i < 360; i++)); do

        # Выбор IP-адреса
        case $((i % 10)) in
            0|1|2|3) ip="192.168.1.10" ;;
            4|5|6) ip="10.0.0.5" ;;
            7|8) ip="172.16.0.8" ;;
            9) ip="192.168.1.20" ;;
        esac

        # Выбор HTTP-метода, пути и кода ответа
        case $((i % 12)) in
            0|6)
                method="POST"
                path="/api/login"
                status=401
                ;;
            1)
                method="GET"
                path="/api/users"
                status=500
                ;;
            2)
                method="GET"
                path="/api/missing"
                status=404
                ;;
            3)
                method="GET"
                path="/api/orders"
                status=503
                ;;
            4)
                method="POST"
                path="/api/users"
                status=201
                ;;
            *)
                method="GET"
                path="/api/users"
                status=200
                ;;
        esac

        printf '%s - - [15/Aug/2026:10:%02d:%02d] "%s %s HTTP/1.1" %s\n' \
            "$ip" "$((i / 60))" "$((i % 60))" \
            "$method" "$path" "$status"

    done > "$log_file"

    echo "Создан тестовый файл: $log_file"
fi

# Проверка существования и доступности файла
if [[ ! -f "$log_file" || ! -r "$log_file" ]]; then
    echo "Ошибка: файл $log_file недоступен" >&2
    exit 1
fi

echo "=== Анализ HTTP-логов ==="

# Общее количество запросов
total=$(awk 'END {print NR+0}' "$log_file")
echo "Общее количество запросов: $total"

# Топ-3 IP-адреса с использованием регулярного выражения
echo "Топ-3 IP-адреса:"

ip_regex='^[0-9]{1,3}(\.[0-9]{1,3}){3} '

if grep -Eq "$ip_regex" "$log_file"; then
    grep -E "$ip_regex" "$log_file" |
        awk '{print $1}' |
        sort |
        uniq -c |
        sort -nr |
        awk 'NR <= 3 {printf "%s — %s запросов\n", $2, $1}'
else
    echo "IP-адреса не найдены"
fi

# Подсчёт ошибок HTTP 4xx
errors_4xx=$(awk '$NF ~ /^4[0-9][0-9]$/ {n++} END {print n+0}' "$log_file")

# Подсчёт ошибок HTTP 5xx
errors_5xx=$(awk '$NF ~ /^5[0-9][0-9]$/ {n++} END {print n+0}' "$log_file")

echo "Количество запросов с кодами 4xx: $errors_4xx"
echo "Количество запросов с кодами 5xx: $errors_5xx"

exit 0
