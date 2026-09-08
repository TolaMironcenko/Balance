# Архитектура Balance (обзор всей системы)

Этот документ описывает, как связаны между собой три подпроекта.
Детальная архитектура каждой платформы — в `docs/ARCHITECTURE.md`
соответствующего подпроекта.

## Общая схема

```text
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  iOS клиент │   │ macOS клиент│   │watchOS клиент│      Apple: SwiftUI + SwiftData
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘      (Balance/)
       │                 │                 │
       └────────┬────────┴────────┬────────┘
                │                 │
      HTTPS (или HTTP только для localhost)
                │                 │
       ┌────────┴────────┐        │
       │  Android клиент │        │   Kotlin + Jetpack Compose + Room
       │ (BalanceAndroid)│        │   (BalanceAndroid/)
       └────────┬────────┘        │
                │                 │
                ▼                 ▼
        ┌───────────────────────────────┐
        │         BalanceServer          │   Go 1.25 + SQLite
        │  ┌───────────┬───────────────┐ │   (BalanceServer/)
        │  │ HTTP API  │ Web-клиент    │ │
        │  │ /v1/*     │ (embedded)    │ │
        │  └───────────┴───────────────┘ │
        └───────────────────────────────┘
```

Каждый нативный клиент (iOS/macOS/watchOS/Android) хранит полную копию
данных локально (SwiftData или Room) и работает офлайн. Сервер —
единственная точка правды при конфликте между устройствами одного
аккаунта: он хранит append-only лог изменений с курсором и применяет
last-write-wins по времени изменения записи (`updatedAt`/`syncUpdatedAt`).

Web-клиент не является отдельным подпроектом — это статические файлы,
встроенные (embed) в Go-бинарник сервера, использующие тот же HTTP API,
что и нативные клиенты, но с cookie-based сессией вместо Bearer-токена.

## Компоненты сервера

- **HTTP API** (`internal/httpapi/`) — auth-эндпоинты и `/v1/sync`.
- **auth** (`internal/auth/`) — пароли (Argon2id), JWT access/refresh
  токены.
- **database** (`internal/database/`) — SQLite-хранилище, схема,
  индексы.
- **config** (`internal/config/`) — переменные окружения.
- **web** (`internal/httpapi/web.go`) — раздача встроенного
  web-приложения.

Подробнее — [`BalanceServer/docs/ARCHITECTURE.md`](../BalanceServer/docs/ARCHITECTURE.md).

## Компоненты Apple-клиента

- **Models** — SwiftData `@Model` сущности.
- **Utilities/FinanceCalculations** — единый источник правил расчёта
  баланса и аналитики.
- **Shared/ServerSync** — HTTP-клиент, авторизация, sync orchestration,
  Keychain.
- **Views** — общий SwiftUI UI; `BalanceMac/` и `BalanceWatch/` —
  платформенно-специфичные точки входа и экраны.

Подробнее — [`Balance/docs/ARCHITECTURE.md`](../Balance/docs/ARCHITECTURE.md).

## Компоненты Android-клиента

- **data/** — Room entities, DAO, `FinanceMath` (та же роль, что и
  `FinanceCalculations` в Apple-клиенте).
- **sync/** — `ServerApi` (HTTP/auth), `ServerPreferences` (URL/cursor),
  `SecureSessionStore` (Android Keystore), `SyncRepository`
  (orchestration), `SyncWorker` (периодический фон).
- **ui/** — Jetpack Compose экраны, состояние из `MainViewModel`.

Подробнее — [`BalanceAndroid/docs/ARCHITECTURE.md`](../BalanceAndroid/docs/ARCHITECTURE.md).

## Принцип согласованности между платформами

Три клиента реализуют одну и ту же доменную модель и один и тот же
sync-протокол независимо друг от друга, на разных стеках. Это
осознанный компромисс (нативный UX на каждой платформе) с обратной
стороной: любое изменение общего контракта нужно вносить согласованно
в трёх местах. См. `docs/SYNC_PROTOCOL.md` и `docs/DATA_MODEL.md`.
