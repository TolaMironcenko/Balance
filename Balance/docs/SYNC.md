# Серверная синхронизация

## Назначение

`Balance/Shared/ServerSync.swift` реализует авторизацию и двустороннюю синхронизацию с собственным сервером.

Сервер не входит в этот Xcode-проект; клиент ожидает API под базовым URL сервера.

## Хранилище сессии

Сессия содержит:

- access token;
- refresh token;
- expiry;
- user id/email.

Сессия хранится в Keychain с service `BalanceServer`.

В `UserDefaults` хранятся только несекретные sync-настройки:

- server URL;
- device ID;
- cursor;
- last push;
- last sync.

Пароль клиента не сохраняется.

## Endpoints

Клиент использует POST JSON:

```text
POST /v1/auth/register
POST /v1/auth/login
POST /v1/auth/logout
POST /v1/auth/refresh
POST /v1/sync
```

Для авторизованных запросов используется:

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

При HTTP 401 клиент один раз обновляет access token через refresh endpoint и повторяет запрос.

## Валидация server URL

Разрешены:

- `https://...`
- `http://localhost...`
- `http://127.0.0.1...`
- `http://[::1]...`

Удалённый HTTP запрещён.

При смене адреса сервера клиент:
- удаляет сессию;
- удаляет sync cursor/push state;
- требует новую авторизацию.

## Sync request

Логическая форма:

```json
{
  "cursor": 123,
  "deviceId": "UUID",
  "changes": [],
  "pull": true
}
```

Для push `changes` заполнен, `pull=false`.

## Sync change

```json
{
  "entity": "transaction",
  "id": "UUID",
  "deleted": false,
  "updatedAt": "ISO-8601",
  "payload": {}
}
```

Также сервер может возвращать `version` и `sequence`.

Поддерживаемые entity:

```text
transaction
category
budget
```

## Payloads

### transaction

```json
{
  "amount": 1000,
  "date": "2026-09-08T10:00:00.000Z",
  "note": "Кофе",
  "categoryName": "Кофе",
  "categoryIcon": "cup.and.saucer.fill",
  "categoryEmoji": "☕️",
  "categoryColorName": "brown",
  "isBalanceAdjustment": false,
  "kindRawValue": "expense"
}
```

### category

```json
{
  "name": "Кофе",
  "icon": "cup.and.saucer.fill",
  "emoji": "☕️",
  "colorName": "brown",
  "kindRawValue": "expense",
  "createdAt": "2026-09-01T10:00:00.000Z"
}
```

### budget

```json
{
  "categoryName": "Кофе",
  "categoryIcon": "cup.and.saucer.fill",
  "categoryEmoji": "☕️",
  "limit": 5000,
  "monthStart": "2026-09-01T00:00:00.000Z"
}
```

Даты кодируются как ISO-8601; клиент принимает варианты с fractional seconds и без них.

## Push

Клиент отправляет:
1. изменённые transactions;
2. изменённые categories;
3. изменённые budgets;
4. tombstones.

Размер batch — до 100 записей.

Если тело запроса превышает 1.5 MB, batch делится рекурсивно. Один payload больше 256 KB считается слишком большим.

## Pull

Клиент отправляет `pull=true` с cursor и применяет изменения по `sequence`.

После успешного применения сохраняется новый cursor.

Если сервер сообщает `hasMore=true`, клиент продолжает pagination до завершения.

Клиент защищается от:
- уменьшения cursor;
- `hasMore=true` без продвижения cursor.

## Conflict resolution

При применении входящего изменения запись обновляется только если:

```text
local.syncUpdatedAt < remote.updatedAt
```

Для удаления используется аналогичная проверка:

```text
local.syncUpdatedAt <= remote.updatedAt
```

Это простая last-write-wins стратегия на уровне timestamp.

## Deletions

Удаление локально:

```swift
modelContext.deleteForSync(transaction)
```

создаёт запись в `SyncDeletionStore`.

При sync она отправляется как:

```json
{
  "entity": "transaction",
  "id": "...",
  "deleted": true,
  "updatedAt": "..."
}
```

После получения соответствующего server change tombstone удаляется из локального журнала.

## Полная пересинхронизация

`resetSynchronization()` очищает cursor и last-push timestamp текущего server/user context, после чего выполняет обычный sync.

Это не удаляет локальные финансовые записи автоматически.

## Автосинхронизация

Apple clients запускают sync:
- после авторизации;
- при запуске/появлении root view;
- затем примерно каждые 120 секунд, пока цикл жив;
- вручную из Settings.

Фактическая фоновая работа всё равно зависит от lifecycle ОС.

## Совместимость

Клиент специально распознаёт `invalid_json` на `/v1/sync` и сообщает, что Balance Server нужно обновить до версии, совместимой с текущим архивом.

Клиент и сервер желательно обновлять согласованно.
