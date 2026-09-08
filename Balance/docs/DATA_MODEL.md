# Модель данных

## Persisted schema

```text
FinanceTransaction
CustomCategory
MonthlyBudget
SyncTombstone
```

## FinanceTransaction

| Поле | Тип | Назначение |
|---|---|---|
| `id` | UUID | стабильный идентификатор |
| `amount` | Double | положительная сумма |
| `date` | Date | дата операции |
| `note` | String | заметка |
| `categoryName` | String | snapshot имени категории |
| `categoryIcon` | String | SF Symbol |
| `categoryEmoji` | String | emoji, если используется |
| `categoryColorName` | String | имя цвета |
| `isBalanceAdjustment` | Bool | специальная корректировка |
| `kindRawValue` | String | `income` / `expense` |
| `syncUpdatedAt` | Date | версия изменения |

## CustomCategory

| Поле | Тип |
|---|---|
| `id` | UUID |
| `name` | String |
| `icon` | String |
| `emoji` | String |
| `colorName` | String |
| `kindRawValue` | String |
| `createdAt` | Date |
| `syncUpdatedAt` | Date |

Имя пользовательской категории уникально без учёта регистра/диакритики относительно системных и других пользовательских категорий.

При редактировании категории текущая реализация распространяет новое имя и presentation metadata на связанные транзакции и бюджеты.

## MonthlyBudget

| Поле | Тип |
|---|---|
| `id` | UUID |
| `categoryName` | String |
| `categoryIcon` | String |
| `categoryEmoji` | String |
| `limit` | Double |
| `monthStart` | Date |
| `syncUpdatedAt` | Date |

Бюджет идентифицируется UUID, но связывается с категорией по сохранённому `categoryName`.

## SyncTombstone

| Поле | Тип |
|---|---|
| `id` | UUID |
| `entity` | String |
| `recordID` | String |
| `updatedAt` | Date |

В текущем клиентском sync-flow tombstone удалений хранится в `SyncDeletionStore` (`UserDefaults`) и отправляется как `deleted: true`.

Поддерживаемые entity:

```text
transaction
category
budget
```

## Финансовые инварианты

1. `amount` не должен быть отрицательным через пользовательский UI.
2. Тип операции хранится в `kindRawValue`.
3. Баланс:
   `sum(income.amount) - sum(expense.amount)`.
4. Корректировка баланса является обычной транзакцией для общего баланса, но не участвует в периодической аналитике.
5. `syncUpdatedAt` должен меняться при каждом изменении синхронизируемой сущности.
6. Удаляемая синхронизируемая сущность должна создавать tombstone.

## Почему категория хранится snapshot'ом

Операция хранит `categoryName`, `categoryIcon`, `categoryEmoji` и `categoryColorName`, а не relationship на `CustomCategory`.

Это позволяет:
- не терять отображение старой операции при удалении категории;
- синхронизировать запись без SwiftData relationship;
- поддерживать системные категории без persisted object.

Из-за этого переименование пользовательской категории должно явно обновлять связанные записи — именно так работает текущая реализация.
