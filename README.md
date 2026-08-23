# Goncharoff.pro

Rails-monolith для публичного сайта, административной панели и будущих CMS/API/CRM-модулей. На первом этапе реализованы технический фундамент, Rails-native authentication и каркас админки.

## Стек

- Ruby 3.4.7
- Ruby on Rails 8.1.3.1
- PostgreSQL 18.4
- ERB, Hotwire (Turbo + Stimulus), Tailwind CSS 4
- Active Storage, Active Job, Solid Queue, Solid Cache, Solid Cable
- Propshaft, Puma
- Docker Compose для локальной разработки; production Docker stage совместим с будущей настройкой Kamal

Redis, Node.js backend, React и отдельный frontend не используются.

## Требования

- Docker Desktop с Docker Compose (Windows/WSL2, macOS) либо Docker Engine + Compose (Linux)
- Git

Для запуска без Docker дополнительно нужны Ruby 3.4.7 и PostgreSQL 18.

## Запуск через Docker

Скопируйте файл окружения и обязательно замените значения `DATABASE_PASSWORD`, `ADMIN_EMAIL` и `ADMIN_PASSWORD`:

```bash
cp .env.example .env
docker compose build
docker compose up
```

При первом старте контейнер автоматически:

1. дождётся PostgreSQL;
2. создаст и подготовит primary/cache/queue/cable базы;
3. выполнит idempotent seed администратора;
4. запустит Puma, Tailwind watcher и Solid Queue worker.

База хранится в named volume `postgres_data` и сохраняется после `docker compose down`. Команда `docker compose down -v` удалит volume и данные — используйте её только осознанно.

Полезные команды:

```bash
docker compose exec app bin/rails db:prepare
docker compose exec app bin/rails db:seed
docker compose exec app bin/rails console
```

## Запуск без Docker

Установите зависимости, создайте PostgreSQL-пользователя и передайте переменные окружения из `.env.example` средствами вашей оболочки. Для локального PostgreSQL используйте `DATABASE_HOST=localhost`.

```bash
bundle install
bin/rails db:prepare db:seed
bin/dev
```

`bin/dev` запускает web server, Tailwind watcher и Solid Queue worker.

## Адреса

- Публичная страница: http://localhost:3000
- Вход: http://localhost:3000/login
- Панель управления: http://localhost:3000/admin
- Health check: http://localhost:3000/up

Регистрации нет. Первый администратор создаётся только из `ADMIN_EMAIL` и `ADMIN_PASSWORD`; пароль не хранится в исходном коде и не выводится приложением.

## Проверки

```bash
docker compose exec app bin/rails test
docker compose exec app bin/rubocop
docker compose exec app bin/brakeman --no-pager
```

Без Docker используйте те же команды без префикса `docker compose exec app`.

## Архитектура

- `HomeController` и ERB view — минимальная публичная часть.
- `SessionsController` — session-based Rails-native authentication без Devise и регистрации.
- `Admin::BaseController` защищает весь namespace `/admin/*`.
- `Admin::DashboardController` и отдельный admin layout формируют каркас панели.
- `/api/v1` и `/webhooks` зарезервированы читаемыми namespace в routes, без пустых контроллеров.
- `User` — единственная доменная модель текущего этапа; роли: `admin`, `editor`.
- Active Storage использует local storage в development и легко переключается через `config/storage.yml`.
- Solid Queue, Cache и Cable используют отдельные PostgreSQL-базы в development/production.

## Переменные окружения

| Переменная | Назначение |
| --- | --- |
| `DATABASE_HOST`, `DATABASE_PORT` | Адрес PostgreSQL |
| `DATABASE_NAME` | Имя основной БД |
| `DATABASE_USERNAME`, `DATABASE_PASSWORD` | Доступ к PostgreSQL |
| `DATABASE_CACHE_NAME`, `DATABASE_QUEUE_NAME`, `DATABASE_CABLE_NAME` | Необязательные имена Solid-баз |
| `APP_HOST` | Публичный host приложения |
| `APP_TIME_ZONE` | Часовой пояс Rails; timestamps хранятся в UTC |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | Данные первого администратора для seed |

Файл `.env` исключён из Git. Production-секреты Rails можно хранить в credentials; ключи credentials также исключены из репозитория.

## Production

Production разворачивается GitHub Actions на сервер `78.24.217.140` после успешных тестов при каждом push в `main`. PostgreSQL и Active Storage используют постоянные Docker volumes, а перед переключением приложения создаётся дамп всех PostgreSQL-баз.

Конфигурация находится в `compose.production.yaml`, workflow — в `.github/workflows/deploy.yml`, серверные сценарии — в `ops/`. Деплой выполняется rootless Docker от имени `test.goncharoff.pro` в `~/app`; реальный `~/app/shared/.env`, SSH-ключи и Rails master key в репозиторий не добавляются.
