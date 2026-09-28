# Тестовое приложение DevOps

**Виктор Юрочкин** · [Инфраструктура и материалы диплома](https://github.com/victoryurochkin/devops-diplom-yandexcloud)

Статическая HTML-страница на nginx. Собственный Dockerfile использует официальный
образ nginx, закреплённый по digest. Процесс работает от пользователя nginx.

| Endpoint | Результат |
|---|---|
| / | Страница приложения и имя автора |
| /healthz | HTTP 200, тело ok |
| /grafana/ | Ссылка на Grafana; маршрут обслуживается Traefik в кластере |

Порт контейнера — 8080. Локальная сборка и проверка:

    docker build -t devops-diplom-app:local .
    ./scripts/test-image.sh devops-diplom-app:local
    docker run --rm -p 127.0.0.1:8080:8080 devops-diplom-app:local

Тест проверяет конфигурацию nginx, готовность HTTP, содержимое страницы и /healthz.
Тестовый контейнер удаляется при завершении скрипта.

## CI/CD

[Workflow](.github/workflows/app.yml) доступен в [GitHub Actions](https://github.com/victoryurochkin/devops-diplom-app/actions).

| Событие | Действия |
|---|---|
| Push в любую ветку | Сборка, тесты, публикация sha-образа |
| Push Git-тега | Сборка, тесты, публикация Docker-тега и OCI version label, деплой по digest |
| Ручной workflow_dispatch | Сборка, тесты и публикация без деплоя |

Образ публикуется только после успешных тестов. Публикация выполняется максимум
за три попытки. Ошибка последней попытки завершает job с ошибкой.
CD ожидает rollout, проверяет digest Deployment, страницу и /healthz на обоих workers.
Для HTTP предусмотрены ограниченные повторы при временной недоступности.

Сборка выполняется на GitHub-hosted ubuntu-24.04. Деплой — на self-hosted runner
it с меткой diplom-deploy, от пользователя diplom-runner без sudo и группы docker.
Runner не выполняет checkout для CD. ServiceAccount app-deployer имеет доступ
к Deployment diplom-app и чтению подов в namespace diplom-app.
Краткоживущий kubeconfig обновляет служба обслуживания инфраструктуры.

Настройки репозитория:

| Тип | Имя | Содержимое |
|---|---|---|
| Secret | YC_REGISTRY_PUSHER_KEY | Авторизованный ключ аккаунта container-registry.images.pusher |
| Variable | IMAGE_REPOSITORY | Адрес репозитория образов |
| Variable | APP_WORKER_IPS | Два публичных IPv4 workers через пробел |

Переменные обновляются из Terraform outputs скриптом sync-app-ci-vars.py
инфраструктурного репозитория. Приватный Registry требует авторизации.

## Рабочий стенд

- [Приложение, worker-1](http://158.160.31.109/)
- [Приложение, worker-2](http://158.160.228.171/)
- [Grafana](http://158.160.31.109/grafana/)
- [Успешный релиз v1.0.2](https://github.com/victoryurochkin/devops-diplom-app/actions/runs/36449846882)

Образ:

    cr.yandex/crp77uvg5d2tuusdlk1f/devops-diplom-app:v1.0.2

Digest проверенного релиза:

    sha256:0ffb78eac3a82faf5fdf93c697aa321e3bd921020a58a1ad918778060c4e2eab

Новую версию выпускают новым Git-тегом на проверенном коммите.
Уже опубликованные release-теги не переносятся. Коммит документации запускает CI,
но не меняет работающий релиз.
