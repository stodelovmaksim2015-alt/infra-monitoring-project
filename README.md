
# Infrastructure Monitoring Project

Проект для мониторинга доступности API, анализа HTTP-логов и контейнеризации сервисов.

## 1. Используемые технологии

Ubuntu Linux и Bash
Git и GitHub
curl, grep, awk, sort, uniq
Wireshark
Docker и Docker Compose
Nginx
GitHub Actions
SSH и SCP

## 2. Структура проекта

`check_api.sh` — мониторинг доступности API.
`analyze_logs.sh` — генерация и анализ HTTP-логов.
`docker-compose.yml` — конфигурация Docker Compose.
`nginx/default.conf` — конфигурация обратного прокси.
`.github/workflows/ci.yml` — автоматические проверки CI.
`.gitignore` — исключение логов, временных файлов и секретов.
`README.md` — документация проекта.

## 3. Требования для запуска

Необходимы Linux или WSL 2, Bash, curl, Git и Docker с поддержкой Compose.

## 4. Мониторинг API

Сделать скрипт исполняемым:

```bash
chmod +x check_api.sh
```

Проверить доступный API:

```bash
./check_api.sh https://httpbin.org/status/200
echo $?
```

Ожидаемый результат: `API доступен`, код завершения `0`.

Проверить ответ 404:

```bash
./check_api.sh https://httpbin.org/status/404
echo $?
```

Ожидаемый результат: `API недоступен, код ответа: 404`, код завершения `1`.

При сетевой ошибке или некорректном URL скрипт также возвращает `1`.

## 5. Анализ HTTP-логов

Сделать скрипт исполняемым:

```bash
chmod +x analyze_logs.sh
```

Запустить:

```bash
./analyze_logs.sh
```

Если файл `access.log` отсутствует, скрипт создаёт тестовый лог из 360 записей.

Результат анализа включает:
 Общее количество HTTP-запросов.
 Топ-3 IP-адреса по количеству запросов.
 Количество ответов с кодами 4xx.
 Количество ответов с кодами 5xx.

Проверить количество строк:

```bash
wc -l access.log
```

Проанализировать существующий файл:

```bash
./analyze_logs.sh access.log
```

Логи исключены из Git с помощью `.gitignore`.

## 6. Запуск Docker Compose

Выполнить из корня проекта:

```bash
docker compose config --quiet
docker compose up -d
docker compose ps
```

Стек состоит из двух сервисов:

- `api` — hashicorp/http-echo, порт 8080.
- `proxy` — nginx:alpine, проксирует HTTP-запросы на `api:8080`.

Контейнеры взаимодействуют через внутреннюю сеть Docker.

Проверить работу:

```bash
curl http://localhost:80
```

Ожидаемый ответ:

```text
Monitoring Service Active
```

Остановить контейнеры:

```bash
docker compose down
```

## 7. Анализ сетевого трафика

Для анализа используется Wireshark.

Порядок действий:

1. Выбрать сетевой интерфейс.
2. Запустить захват трафика.
3. Выполнить HTTP-запросы с помощью curl.
4. Применить фильтр `http` или `tls || http`.
5. Проанализировать IP-адреса, HTTP-методы и коды ответов.
6. Сохранить захват в формате `.pcapng`.

Для HTTPS содержимое HTTP-запросов обычно зашифровано TLS. Для наблюдения открытых HTTP-заголовков использовался локальный HTTP-сервер.

## 8. CI/CD — GitHub Actions

Workflow расположен в `.github/workflows/ci.yml`.

Автоматические проверки запускаются при отправке изменений в `feature/monitoring` и при создании или обновлении Pull Request в `main`.

Пайплайн выполняет:

 Проверку синтаксиса обоих Bash-скриптов.
 Проверку доступности API с ожидаемым HTTP 200.
 Запуск анализатора логов.
 Проверку генерации минимум 300 записей.

Результаты доступны во вкладке Actions репозитория GitHub.

## 9. Безопасное подключение через SSH

SSH обеспечивает защищённое соединение с удалённым сервером.

Ниже приведены примеры команд для Linux. Значения `deploy` и `SERVER_IP` необходимо заменить на реальные имя пользователя и адрес сервера.

Создать отдельную пару SSH-ключей:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_infra
```

При создании ключа рекомендуется задать парольную фразу.

Передать публичный ключ на сервер:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_infra.pub deploy@SERVER_IP
```

Проверить SSH-подключение:

```bash
ssh -i ~/.ssh/id_ed25519_infra deploy@SERVER_IP
```

Приватный SSH-ключ нельзя публиковать в GitHub или передавать другим пользователям.

## 10. Передача проекта через SCP

Создать архив проекта без Git-истории, логов и локальных секретов:

```bash
tar --exclude='.git' --exclude='*.log' --exclude='.env' --exclude='.env.*' -czf /tmp/infra-monitoring-project.tar.gz -C "$HOME" infra-monitoring-project
```

Передать архив на сервер по защищённому соединению:

```bash
scp -i ~/.ssh/id_ed25519_infra /tmp/infra-monitoring-project.tar.gz deploy@SERVER_IP:/tmp/
```

Подключиться к удалённому серверу:

```bash
ssh -i ~/.ssh/id_ed25519_infra deploy@SERVER_IP
```

Распаковать архив:

```bash
tar -xzf /tmp/infra-monitoring-project.tar.gz -C ~
```

При условии, что Docker и Docker Compose установлены на сервере, запустить проект:

```bash
cd ~/infra-monitoring-project
docker compose up -d
docker compose ps
```

Перед развёртыванием необходимо проверить доступность нужных портов и права пользователя на запуск Docker.

## 11. Git Workflow

Основная ветка проекта — `main`, рабочая ветка — `feature/monitoring`.

Разработка ведётся в рабочей ветке. Изменения фиксируются осмысленными коммитами.

Готовые изменения объединяются с `main` посредством Pull Request после успешного прохождения CI/CD.
