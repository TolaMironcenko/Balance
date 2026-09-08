# Архитектура Balance Android

## Слои

```text
Jetpack Compose
      │
      ▼
 MainViewModel
      │
      ├──────────────► FinanceMath
      │
      ▼
 FinanceDao ────────► Room / SQLite
      │
      └──────────────► SyncRepository
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
             ServerApi        SecureSessionStore
                 │                   │
                 ▼                   ▼
          BalanceServer        Android Keystore
```

## Application

`BalanceApplication` создаёт singleton-зависимости:

- `AppDatabase`
- `ServerPreferences`
- `SecureSessionStore`
- `SyncRepository`

Также регистрирует уникальный WorkManager job `balance-periodic-sync`.

## UI

`MainActivity` запускает Compose root.

`BalanceRoot` содержит навигацию между:
- Обзор;
- Аналитика;
- Операции;
- Бюджеты;
- Настройки;
- Категории;
- Сервер и синхронизация.

`MainViewModel` объединяет Room flows, sync status/session и настройки в `FinanceUiState`.

## Data

Room database называется `balance-android.db`.

Entities:
- `TransactionEntity`
- `CategoryEntity`
- `BudgetEntity`
- `DeletionEntity`

`FinanceDao` предоставляет Flow для UI и suspend-операции для записи/sync.

## Sync

Sync двухфазный:

```text
local changes → push
server changes → pull
```

Push идёт пакетами до 100 изменений. Большой JSON (> 1.5 MB) рекурсивно разбивается.

Pull использует server cursor и `hasMore`.

Remote changes применяются атомарно через Room transaction.

## Conflict resolution

Стратегия — timestamp-based last-write-wins:

```text
remote.updatedAt > local.updatedAt
```

Если локальная запись новее или равна, remote payload не заменяет её.

## Background sync

WorkManager запускается с:
- периодом 15 минут;
- `NetworkType.CONNECTED`.

Worker ничего не делает без server session/server URL.

Ограничения Android могут отложить фактический запуск; 15 минут — минимальный период WorkManager, а не гарантия точного времени запуска.

## Платформа

Android-клиент не использует CloudKit. Локальное хранение всегда Room; синхронизация с другими клиентами выполняется через BalanceServer.
