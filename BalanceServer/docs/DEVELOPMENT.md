# Разработка и запуск

## Требования

Проект использует Go 1.25.0.

Проверить локальную версию:

```bash
go version
```

## Установка зависимостей

```bash
go mod download
```

## Сборка

```bash
go build ./...
```

## Тесты

```bash
go test ./...
```

С race detector:

```bash
go test -race ./...
```

## Static checks

```bash
go vet ./...
```

Если в проекте есть Makefile/CI, его команды имеют приоритет как canonical build pipeline.

## Локальный запуск

Перед запуском изучите конфигурацию в коде и `.env`/deployment files.

Не коммитьте реальные credentials.

Пример общего workflow:

```bash
go mod download
go test ./...
go build ./...
./<server-binary>
```

Имя binary и обязательные env vars определяются текущей entrypoint/config реализацией.

## Database

Перед первым запуском:
1. поднять требуемую БД;
2. применить migrations, если проект их использует;
3. задать connection settings;
4. проверить health/startup logs.

## Production

Рекомендуемый pipeline:

```text
source
  ↓
go test ./...
  ↓
go vet ./...
  ↓
go build ./...
  ↓
container/package
  ↓
deploy
  ↓
health check
```

Для production нужны:
- TLS termination;
- persistent database;
- backups;
- monitoring;
- log rotation;
- secrets management;
- migration procedure.

## Совместимость

При релизе server проверяйте минимум:
- старый iOS client + новый server;
- новый iOS client + server;
- Android client + server;
- concurrent sync с двух устройств;
- login/refresh после истечения access token;
- delete → pull на другом устройстве.
