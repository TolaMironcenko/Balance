# Deployment

## Компоненты

```text
Internet
   │
 HTTPS
   │
   ▼
Reverse proxy / Load Balancer
   │
   ▼
BalanceServer
   │
   ▼
Database
```

## Configuration

Все environment variables и flags должны задаваться через deployment environment, а не hard-code в Go.

Перед production deployment составьте список переменных, которые реально читает текущий код:

```text
- docker-compose.yml
- docker-compose.yml
- docker-compose.yml
- go.mod
- README.md
- README.md
- README.md
- Dockerfile
- Dockerfile
- Dockerfile
- internal/database/database.go
- internal/database/database.go
- internal/database/database.go
- internal/config/config.go
- internal/config/config.go
- internal/config/config.go
- internal/auth/tokens.go
- internal/auth/tokens.go
- internal/auth/tokens.go
- internal/auth/password.go
```

## Docker

Если репозиторий содержит Dockerfile/compose, используйте их как canonical deployment recipe.

Не включайте secrets в Docker image.

## Health/readiness

Если проект предоставляет health endpoint, load balancer должен использовать его для readiness.

Database connectivity желательно проверять отдельно от liveness.

## Database migrations

Migration должна выполняться контролируемо:

```text
backup
  ↓
migration
  ↓
health check
  ↓
application rollout
```

Не запускайте destructive migration автоматически без backup/rollback plan.

## Backups

Финансовые данные — пользовательские данные высокой ценности.

Минимум:
- регулярные DB backups;
- retention policy;
- периодическая проверка restore;
- encrypted backup storage.

## Observability

Рекомендуется мониторить:
- HTTP 5xx;
- auth failures;
- sync failures;
- latency;
- DB latency/errors;
- active users/devices;
- size/lag of sync change log;
- disk/storage usage.

## Release checklist

- [ ] Tests green.
- [ ] Database migrations проверены.
- [ ] Backup создан.
- [ ] Secrets injected через secure mechanism.
- [ ] HTTPS включён.
- [ ] Health checks работают.
- [ ] Sync tested with both mobile clients.
- [ ] Rollback plan готов.
