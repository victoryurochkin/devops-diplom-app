# Тестовое приложение диплома DevOps

Автор: Виктор Юрочкин.

Статическая HTML-страница с собственными Dockerfile и конфигурацией nginx.

Инфраструктура:
https://github.com/victoryurochkin/devops-diplom-yandexcloud

## Устройство приложения

- Базовый официальный образ nginx закреплён по digest в Dockerfile.
- nginx работает от пользователя nginx, без root.
- Порт контейнера: 8080.
- `/` — страница приложения.
- `/healthz` — проверка работоспособности, ответ `ok`.
- Ссылка `/grafana/` рассчитана на размещение приложения за Traefik.

## Сборка и проверка

    docker build -t devops-diplom-app:local .
    ./scripts/test-image.sh devops-diplom-app:local

Проверяются конфигурация nginx, HTTP-доступность,
содержимое страницы и endpoint `/healthz`.
Тестовый контейнер удаляется после проверки.

## Локальный запуск

    docker run --rm -p 127.0.0.1:8080:8080 devops-diplom-app:local

Приложение: http://127.0.0.1:8080/

## Публикация

Репозиторий образов:
`cr.yandex/crp77uvg5d2tuusdlk1f/devops-diplom-app`.

Для первоначальной ручной публикации используется тег
`sha-<12 символов коммита>`.
Registry приватный: для push и pull требуется авторизация.

## Статус

- [x] Подготовлены Dockerfile, nginx.conf и HTML-страница.
- [x] Локальная сборка и проверка контейнера выполнены.
- [x] Настроены автоматическая сборка, тестирование и push при коммите.
- [x] Настроен автоматический деплой при создании Git-тега.

## CI/CD приложения

Workflow: .github/workflows/app.yml в репозитории devops-diplom-app.

При push в любую ветку GitHub Actions собирает образ, проверяет
конфигурацию nginx, HTTP-страницу и /healthz, затем публикует образ
с тегом sha-<12 символов коммита>. При ошибке тестов публикация не выполняется.

При push Git-тега создаётся образ с соответствующим Docker-тегом
и OCI label org.opencontainers.image.version.
После успешной сборки и тестов запускается деплой по digest,
ожидание rollout и HTTP-проверки через оба worker.

Сборка выполняется на GitHub-hosted runner ubuntu-24.04.
Деплой выполняется на VM it через self-hosted runner
diplom-app-deploy-it с меткой diplom-deploy.
Runner работает как systemd-служба от пользователя diplom-runner,
без членства в группах sudo и docker.

Для публикации используется Actions Secret YC_REGISTRY_PUSHER_KEY.
Kubeconfig деплоя находится локально на runner:
 /home/diplom-runner/.kube/config
Он использует ServiceAccount diplom-app/app-deployer.
RBAC разрешает изменение Deployment diplom-app и чтение подов
в namespace diplom-app.

Проверенный релиз в пересозданном кластере: v1.0.1.
Образ: cr.yandex/crp77uvg5d2tuusdlk1f/devops-diplom-app:v1.0.1
Digest: sha256:f9640c98a09da6d87086a89b287399c73cf61229981097dc57f0bf8bb2ba24eb

Успешный запуск (попытка 2):
https://github.com/victoryurochkin/devops-diplom-app/actions/runs/36427694065

Первая попытка остановилась при публикации с ответом Registry HTTP 503.
Повторный запуск завершил сборку, тесты, публикацию и деплой.

После деплоя: Deployment 2/2, обе реплики Running,
HTTP-проверки приложения прошли.

### Параметры инфраструктуры для CI/CD

Workflow использует GitHub Actions Variables:
- IMAGE_REPOSITORY — адрес репозитория образов.
- APP_WORKER_IPS — два публичных IPv4 workers через пробел.

Значения обновляются из Terraform outputs скриптом
scripts/sync-app-ci-vars.py в инфраструктурном репозитории.
После пересоздания инфраструктуры синхронизация выполняется
до запуска сборки и деплоя приложения.

## Доступ после пересоздания инфраструктуры

Приложение:

- http://158.160.31.109/
- http://158.160.228.171/

Grafana: http://158.160.31.109/grafana/

Релиз v1.0.1 автоматически развёрнут в новом кластере 28.09.2026.
Проверены две реплики на разных workers, страница приложения и /healthz.
