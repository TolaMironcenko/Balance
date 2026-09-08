# Архитектура Balance

## Обзор

Balance использует простую feature-oriented структуру поверх SwiftUI + SwiftData:

```text
SwiftUI Views
    │
    ├── FinanceCalculations
    │
    ├── SwiftData ModelContext / @Query
    │
    └── ServerAccountStore
             │
             ├── Keychain (session)
             ├── UserDefaults (server URL, cursor, sync metadata)
             └── HTTP(S) API /v1/*
```

Общий код находится в `Balance/Balance/`. Платформенные оболочки находятся в `BalanceMac/` и `BalanceWatch/`.

## Точки входа

| Platform | Entry point | Основной root |
|---|---|---|
| iOS | `Balance/App/BalanceApp.swift` | `ContentView` |
| macOS | `BalanceMac/BalanceMacApp.swift` | `MacContentView` |
| watchOS | `BalanceWatch/BalanceWatchApp.swift` | `WatchRootView` |

Каждое приложение создаёт `BalanceModelContainer.make()` и передаёт его через `.modelContainer(...)`.

## Хранение данных

`BalanceModelContainer` выбирает конфигурацию:

1. если `BalanceCloudKitEnabled == true` и CloudKit container создаётся — SwiftData + CloudKit;
2. иначе — локальная SwiftData база;
3. если локальная база не создаётся — используется in-memory recovery container.

Recovery container предназначен для предотвращения падения приложения при невозможности открыть persistent store; он не является способом восстановления данных.

## Модели

### FinanceTransaction

Основная финансовая операция:

- UUID;
- сумма `Double`;
- дата;
- заметка;
- snapshot категории;
- тип `income` / `expense`;
- флаг корректировки баланса;
- `syncUpdatedAt`.

`TransactionKind` сериализуется через `kindRawValue`, а наружу предоставляется computed property `kind`.

### CustomCategory

Пользовательская категория:

- имя;
- SF Symbol или emoji;
- цвет;
- тип операции;
- `createdAt`;
- `syncUpdatedAt`.

### MonthlyBudget

Месячный лимит для категории:

- snapshot категории;
- `limit`;
- `monthStart`;
- `syncUpdatedAt`.

### SyncTombstone

SwiftData-модель для совместимости схемы, но клиентский журнал удалений фактически ведётся через `SyncDeletionStore` в `UserDefaults`. Это сделано специально, чтобы удаление не зависело от миграции основной SwiftData-схемы.

## Расчёты

`FinanceCalculations` — чистый доменный слой:

- `totalBalance` считает весь баланс;
- `monthInterval` возвращает календарный месяц;
- `summary` считает доходы/расходы периода;
- `spendingByCategory` агрегирует расходы.

Корректировки (`isBalanceAdjustment`) влияют на `totalBalance`, но исключаются из `summary` и `spendingByCategory`.

## UI/features

Общие features:

- Dashboard
- Transactions
- Budgets
- Analytics
- Categories
- Settings
- Balance Adjustment
- CSV export
- Server account/sync

macOS добавляет полноценную desktop-навигацию и расширенный аналитический экран.

watchOS использует отдельные экраны с теми же моделями и расчётами, но адаптированным UI.

## Состояние приложения

`@Query` используется как основной способ наблюдения за SwiftData. Feature views не должны создавать собственные параллельные кеши финансовых сущностей без необходимости.

Глобальное состояние серверного аккаунта сосредоточено в `ServerAccountStore.shared`.

Настройки пользователя хранятся через `@AppStorage`, в частности:

- `currencyCode`;
- `appTheme`;
- server URL;
- sync cursor;
- last push/sync timestamps.

## Принцип изменения

Предпочтительный поток:

```text
UI action
  → update/insert/delete SwiftData
  → update syncUpdatedAt / tombstone
  → UI обновляется через @Query
  → ServerAccountStore синхронизирует изменения
```

Не следует делать HTTP-запросы непосредственно из feature view.
