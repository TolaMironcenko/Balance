# Серверная синхронизация

Android-клиент использует тот же self-hosted BalanceServer, что и остальные клиенты Balance.

## API

POST endpoints:

```text
/v1/auth/register
/v1/auth/login
/v1/auth/logout
/v1/auth/refresh
/v1/sync
```

Авторизованный запрос:

```http
Authorization: Bearer <access-token>
Content-Type: application/json; charset=utf-8
```

## Session

`ServerSession` содержит:

- access token;
- refresh token;
- expiresAt;
- userId;
- email.

`SecureSessionStore` сериализует session JSON и шифрует его AES/GCM.

AES key создаётся и хранится в Android Keystore.

При ошибке расшифровки store очищается.

## Server URL

`ServerPreferences.normalizeServer` принимает полный URL без:
- user info;
- query;
- fragment.

Разрешены HTTPS и локальный HTTP.

HTTP допускается для:
- `localhost`
- `127.0.0.1`
- `10.0.2.2`

`10.0.2.2` — специальный адрес Android Emulator для host machine.

## Authentication

Перед авторизованным запросом клиент проверяет expiry.

Если осталось менее 60 секунд, выполняется refresh.

При HTTP 401 клиент один раз refresh-ит session и повторяет исходный запрос.

Если refresh не удался, session очищается.

## Sync request

```json
{
  "cursor": 0,
  "deviceId": "UUID",
  "changes": [],
  "pull": true
}
```

Push использует тот же endpoint с `pull=false`.

## Change envelope

```json
{
  "entity": "transaction",
  "id": "UUID",
  "deleted": false,
  "updatedAt": "2026-09-08T10:00:00Z",
  "payload": {}
}
```

Entities:

```text
transaction
category
budget
```

## Transaction payload

```json
{
  "amount": 1000,
  "date": "2026-09-08T10:00:00Z",
  "note": "Кофе",
  "categoryName": "Кофе",
  "categoryIcon": "cup.and.saucer.fill",
  "categoryEmoji": "☕️",
  "categoryColorName": "brown",
  "isBalanceAdjustment": false,
  "kindRawValue": "expense"
}
```

## Category payload

```json
{
  "name": "Кофе",
  "icon": "cup.and.saucer.fill",
  "emoji": "☕️",
  "colorName": "brown",
  "kindRawValue": "expense",
  "createdAt": "2026-09-01T10:00:00Z"
}
```

## Budget payload

```json
{
  "categoryName": "Кофе",
  "categoryIcon": "cup.and.saucer.fill",
  "categoryEmoji": "☕️",
  "limit": 5000,
  "monthStart": "2026-09-01T00:00:00Z"
}
```

## Push

Изменения выбираются по `updatedAt` между `lastPush` и cutoff.

Batch size: 100.

Если JSON batch больше 1.5 MB, он рекурсивно делится.

## Pull

Клиент отправляет текущий cursor.

Сервер возвращает:

```json
{
  "cursor": 42,
  "changes": [],
  "hasMore": false
}
```

Если `hasMore=true`, клиент повторяет pull с новым cursor.

Есть защитные проверки:
- cursor не может уменьшиться;
- `hasMore=true` должен сопровождаться продвижением cursor.

## Applying remote changes

Изменения сортируются по `sequence`.

Для обычного изменения:

```text
apply remote iff remote.updatedAt > local.updatedAt
```

Для удаления:

```text
delete iff local.updatedAt <= remote.updatedAt
```

После применения соответствующий deletion journal очищается.

## Scope

Cursor и lastPush привязаны к:

```text
serverUrl + userId
```

Это позволяет иметь независимое состояние sync для разных серверов/аккаунтов.

## Reset

`resetAndSync()` очищает cursor и lastPush текущего scope, затем запускает обычную sync.

Локальные финансовые данные при этом не удаляются.

## Background

`SyncWorker`:
- запускается WorkManager;
- требует network connection;
- пропускает работу без session/server URL;
- возвращает `retry`, если sync завершилась ошибкой.

## Совместимость

README проекта указывает совместимость Android-клиента с BalanceServer protocol 3.1. При изменении контракта сервера необходимо синхронно обновлять `ServerApi`, `SyncRepository` и документацию.
