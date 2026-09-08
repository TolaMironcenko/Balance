# AGENTS.md

## Проект

**Balance Android** — нативный Android-клиент приложения Balance для учёта личных финансов. Он повторяет доменную модель iOS/macOS/watchOS-клиентов и синхронизируется с тем же self-hosted BalanceServer.

Стек:
- Kotlin 2.3.21
- Jetpack Compose
- Room
- Coroutines / Flow
- WorkManager
- Android Keystore
- minSdk 26 / compileSdk 36
- Java 17 bytecode

## Структура

```text
BalanceAndroid/
├── app/src/main/java/com/example/balanceandroid/
│   ├── data/       # Room entities, DAO, финансовая математика
│   ├── sync/       # HTTP API, session, preferences, sync repository/worker
│   ├── ui/         # Compose UI и theme
│   ├── MainActivity.kt
│   ├── MainViewModel.kt
│   └── BalanceApplication.kt
├── app/src/test/   # unit tests
├── app/src/main/res/
└── docs/
```

## Правила

### Data layer

- Все persisted финансовые сущности находятся в `data/`.
- Доступ к Room выполняется через `FinanceDao`.
- Не помещай HTTP или Compose-логику в DAO.
- Изменение Room entities требует проверки schema/migration.
- `updatedAt` — timestamp версии записи и обязателен для syncable entities.

### Финансовая логика

`FinanceMath` является единым источником правил расчёта.

- balance = income − expense;
- balance adjustments влияют на общий баланс;
- adjustments исключаются из периодической аналитики;
- spending группируется по `categoryName`.

При изменении правил обновляй `FinanceMathTest`.

### Удаления

Для синхронизируемых объектов нельзя использовать только прямой `DELETE`.

Используй DAO-методы:
- `deleteTransaction`
- `deleteCategory`
- `deleteBudget`

Они сначала создают запись в `deletion_journal`, затем удаляют объект.

### Категории

Категория хранится snapshot-полями в transactions/budgets. Поэтому при переименовании пользовательской категории текущая реализация обновляет связанные операции и бюджеты. Сохраняй это поведение.

### Sync

`SyncRepository` — единственная точка orchestration синхронизации.

- `ServerApi` отвечает только за HTTP/auth.
- `ServerPreferences` отвечает за URL, cursor и sync metadata.
- `SecureSessionStore` отвечает за зашифрованную сессию.
- `SyncWorker` запускает периодическую sync-задачу.

Не делай network calls непосредственно из Compose UI.

### Security

- Access/refresh tokens не должны попадать в обычные SharedPreferences.
- Не логируй tokens/passwords/Authorization.
- Session хранится через AES/GCM с ключом Android Keystore.
- Для удалённого сервера нужен HTTPS.
- HTTP разрешён только локальным адресам, предусмотренным `ServerPreferences`.
- Не добавляй credentials или production secrets в репозиторий.

### Compose

- UI state идёт из `MainViewModel`.
- Данные Room наблюдаются через Flow.
- Общие компоненты — `ui/Components.kt`; feature screens — `ui/BalanceRoot.kt` и `ui/Editors.kt`.
- Не переносить бизнес-логику в composables.

### Sync invariants

При изменении syncable entity:
1. сохранить новое значение;
2. обновить `updatedAt`;
3. дождаться следующего sync.

При удалении:
1. создать deletion journal;
2. удалить локальную запись;
3. отправить tombstone на сервер.

Remote change применяется только если его `updatedAt` новее локального.

## Тестирование

Минимум:

```bash
./gradlew test
```

Перед PR желательно:

```bash
./gradlew clean test assembleDebug
```

Если менялся sync/data layer, добавь unit tests для новых инвариантов.

## PR checklist

- [ ] Изменён правильный слой.
- [ ] Финансовая логика остаётся в `FinanceMath`.
- [ ] Изменения persisted schema учтены.
- [ ] `updatedAt` обновляется.
- [ ] Deletes создают tombstones.
- [ ] Sync не вызывается напрямую из UI.
- [ ] Нет секретов в репозитории/logcat.
- [ ] Unit tests проходят.
- [ ] README/docs обновлены при изменении setup/API.
