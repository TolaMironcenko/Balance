# Модель данных

## Room schema

### transactions

`TransactionEntity`:

| Поле | Тип | Назначение |
|---|---|---|
| `id` | String | UUID |
| `amount` | Double | сумма |
| `date` | Long | epoch millis |
| `note` | String | заметка |
| `categoryName` | String | snapshot категории |
| `categoryIcon` | String | иконка |
| `categoryEmoji` | String | emoji |
| `categoryColorName` | String | цвет |
| `isBalanceAdjustment` | Boolean | корректировка |
| `kindRawValue` | String | `income`/`expense` |
| `updatedAt` | Long | версия для sync |

Индексы: `updatedAt`, `date`.

### categories

Пользовательские категории:

- `id`
- `name`
- `icon`
- `emoji`
- `colorName`
- `kindRawValue`
- `createdAt`
- `updatedAt`

Индекс `(name, kindRawValue)` помогает находить категории по имени и типу.

### budgets

- `id`
- `categoryName`
- `categoryIcon`
- `categoryEmoji`
- `limitAmount`
- `monthStart`
- `updatedAt`

### deletion_journal

Локальный журнал tombstones:

- `id = entity:recordId`
- `entity`
- `recordId`
- `updatedAt`

## Built-in categories

Expense:
- Продукты
- Транспорт
- Дом
- Развлечения
- Здоровье
- Покупки
- Подписки
- Образование
- Другое

Income:
- Зарплата
- Подработка
- Инвестиции
- Подарок
- Другое

Они не являются Room entities.

## Финансовые правила

### Общий баланс

```text
sum(income.amount) - sum(expense.amount)
```

`isBalanceAdjustment` здесь не исключается.

### Периодическая аналитика

`FinanceMath.summary` исключает:
- все balance adjustments;
- записи вне `[start, endExclusive)`.

### Spending

`FinanceMath.spending`:
- берёт только expenses;
- исключает adjustments;
- группирует по category name;
- сортирует по убыванию суммы.

## Category snapshot

Transaction и budget не имеют Room relationship на CategoryEntity. Они хранят presentation data непосредственно.

Это позволяет удалять пользовательскую категорию, не разрушая исторические операции.

Поэтому rename категории распространяется вручную на связанные transactions/budgets.
