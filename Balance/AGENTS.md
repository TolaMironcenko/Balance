# AGENTS.md

## Назначение проекта

**Balance** — нативное мультиплатформенное приложение для учёта личных финансов:
- iOS 17+
- macOS 14+
- watchOS 10+

Основной UI написан на SwiftUI, локальное хранилище — SwiftData. Проект поддерживает два взаимоисключающих способа синхронизации данных: CloudKit или собственный HTTP(S)-сервер.

## Структура репозитория

```text
Balance/
├── Balance/                 # Общий код iOS/macOS/watchOS
│   ├── App/                 # Точка входа iOS и корневой ContentView
│   ├── Models/              # SwiftData-модели и доменные типы
│   ├── Shared/              # Общее состояние, контейнер SwiftData, server sync
│   ├── Utilities/           # Чистые функции расчётов и форматирование
│   └── Views/               # Общие SwiftUI-экраны
├── BalanceMac/              # macOS entry point и macOS-specific UI
├── BalanceWatch/            # watchOS entry point и компактный UI
├── BalanceTests/            # XCTest
├── Config/                  # Entitlements
├── Balance.xcodeproj/
└── docs/                    # Архитектура, модель данных, sync и dev guide
```

## Правила разработки

### 1. Сначала определяй слой изменения

- **Модель/данные:** `Balance/Models/`
- **Расчёты:** `Balance/Utilities/FinanceCalculations.swift`
- **Общий сервис:** `Balance/Shared/`
- **Общий UI:** `Balance/Views/`
- **Только Mac:** `BalanceMac/`
- **Только Watch:** `BalanceWatch/`
- **Тесты:** `BalanceTests/`

Не дублируй доменную логику в iOS/macOS/watchOS-экранах, если её можно выразить общей функцией или сервисом.

### 2. SwiftData

Текущая схема зарегистрирована в `BalanceModelContainer.schema`:

- `FinanceTransaction`
- `MonthlyBudget`
- `CustomCategory`
- `SyncTombstone`

При изменении `@Model` учитывай миграции существующих локальных баз. Не удаляй и не переименовывай persisted-поля без явной стратегии миграции.

### 3. Изменения финансовых записей

Любая редактируемая сервером сущность должна обновлять `syncUpdatedAt`.

Для удаления используй:

```swift
modelContext.deleteForSync(...)
```

а не прямой `modelContext.delete(...)`, если сущность должна удалиться и на других устройствах. Это создаёт tombstone в `SyncDeletionStore`.

### 4. Баланс и аналитика

`FinanceCalculations` содержит центральные правила:

- общий баланс = доходы − расходы;
- `isBalanceAdjustment == true` учитывается в общем балансе;
- корректировки не учитываются в периодической аналитике;
- расходы группируются по `categoryName`.

Не меняй эти правила только в одном UI. При изменении поведения обновляй `BalanceTests/FinanceCalculationsTests.swift`.

### 5. Категории

Системные категории находятся в `FinanceCategory`.

Пользовательские категории — `CustomCategory`. Их имя является важной частью текущей модели: операции и бюджеты хранят snapshot имени/иконки/emoji/цвета. При переименовании пользовательской категории текущий код обновляет связанные операции и бюджеты — это поведение нужно сохранять.

### 6. Синхронизация

`ServerAccountStore` — единая точка серверной авторизации и синхронизации.

Не хранить пароль в `UserDefaults`, SwiftData или файлах. Сессия хранится в Keychain.

При изменении URL сервера:
1. текущая сессия очищается;
2. cursor/push state удаляется;
3. пользователь должен авторизоваться заново.

Не включай одновременно CloudKit и собственный сервер как два источника синхронизации одной и той же базы.

### 7. Безопасность

- Для удалённого сервера использовать HTTPS.
- HTTP разрешён клиентом только для `localhost`, `127.0.0.1` и `::1`.
- Access/refresh tokens — только Keychain.
- Не логируй токены, пароли или полные Authorization headers.
- Не добавляй секреты, production URLs или credentials в репозиторий.

### 8. UI

Используй SwiftUI и системные компоненты Apple.

- Общие компоненты размещай в `Balance/Views/Components/`.
- Не тащи macOS-only API в общий код без `#if os(macOS)`.
- Не тащи watchOS-only API в общий код без условной компиляции.
- На Watch предпочитай короткие списки, `Form`, `List`, `NavigationStack` и компактные действия.

### 9. Тестирование

Минимум перед PR:

```bash
xcodebuild -project Balance.xcodeproj -scheme Balance -destination 'platform=iOS Simulator,name=<available iPhone>' test
```

Также полезно проверить Mac и Watch schemes:

```bash
xcodebuild -project Balance.xcodeproj -scheme BalanceMac -showBuildSettings
xcodebuild -project Balance.xcodeproj -scheme BalanceWatch -showBuildSettings
```

Если имя симулятора отличается, сначала получи список:

```bash
xcrun simctl list devices available
```

Не добавляй тесты, которые зависят от текущей даты или локали без явной фиксации `Calendar`, `Date` и formatter.

## Commit/PR checklist

- [ ] Изменение находится в правильном target/layer.
- [ ] Нет дублирования финансовой логики.
- [ ] Все серверные изменения сущностей обновляют `syncUpdatedAt`.
- [ ] Удаления синхронизируемых сущностей используют tombstone.
- [ ] Изменения расчётов покрыты XCTest.
- [ ] Проверены iOS/macOS/watchOS-условия компиляции.
- [ ] Не добавлены секреты и токены.
- [ ] Документация обновлена, если изменились данные, sync API или setup.
