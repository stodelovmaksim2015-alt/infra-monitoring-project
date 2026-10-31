
#!/bin/bash

# Проверяем количество аргументов
if [ "$#" -ne 1 ]; then
    echo "Использование: $0 <URL>"
    exit 1
fi

url="$1"

# Проверяем формат URL
if [[ ! "$url" =~ ^https?:// ]]; then
    echo "Ошибка: URL должен начинаться с http:// или https://"
    exit 1
fi

# Отправляем запрос и получаем HTTP-код
if http_code=$(curl -sS -L -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 20 -- "$url"); then
    :
else
    echo "API недоступен, код ответа: ${http_code:-000}"
    exit 1
fi

# Проверяем ответ сервера
if [ "$http_code" = "200" ]; then
    echo "API доступен"
    exit 0
else
    echo "API недоступен, код ответа: $http_code"
    exit 1
fi
