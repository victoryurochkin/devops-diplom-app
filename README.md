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
`cr.yandex/crp15t94ei4mots103d9/devops-diplom-app`.

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

Проверенный релиз: v1.0.0.
Образ: cr.yandex/crp15t94ei4mots103d9/devops-diplom-app:v1.0.0
Digest: sha256:e7f328f227f530e7604c6afe04f148bff7543563dd982b61fbd4ad7ca8df4315

Успешный запуск:
https://github.com/victoryurochkin/devops-diplom-app/actions/runs/36405099315

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
