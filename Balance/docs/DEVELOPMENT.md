# Разработка

## Требования

- Xcode 16+
- Swift 5
- iOS 17+
- macOS 14+
- watchOS 10+

В проекте нет Swift Package Manager-зависимостей.

## Открытие

```bash
open Balance.xcodeproj
```

Доступные shared schemes:

```text
Balance
BalanceMac
BalanceWatch
```

## Сборка

Сначала можно посмотреть схемы:

```bash
xcodebuild -project Balance.xcodeproj -list
```

Для CI используйте явный `-scheme` и подходящий `-destination`.

Пример проверки компиляции:

```bash
xcodebuild \
  -project Balance.xcodeproj \
  -scheme Balance \
  -destination 'generic/platform=iOS' \
  build
```

Для Mac:

```bash
xcodebuild \
  -project Balance.xcodeproj \
  -scheme BalanceMac \
  -destination 'generic/platform=macOS' \
  build
```

Для Watch:

```bash
xcodebuild \
  -project Balance.xcodeproj \
  -scheme BalanceWatch \
  -destination 'generic/platform=watchOS' \
  build
```

## Тесты

Основной тестовый target:

```text
BalanceTests
```

Запуск:

```bash
xcodebuild \
  -project Balance.xcodeproj \
  -scheme Balance \
  -destination 'platform=iOS Simulator,name=<available iPhone>' \
  test
```

Тесты сосредоточены на финансовых расчётах и sync deletion journal.

## Signing

Проект рассчитан на запуск с собственной Team.

Для обычной локальной разработки:
- выберите свою Team в Signing & Capabilities;
- используйте локальное SwiftData;
- CloudKit можно не включать.

Bundle identifiers текущего проекта:

```text
com.tolamironcenko.Balance
com.tolamironcenko.Balance.mac
com.tolamironcenko.Balance.watchkitapp
```

При публикации их следует заменить на собственные identifiers.

## Local mode

Без `BalanceCloudKitEnabled=YES` приложение использует локальное SwiftData-хранилище.

Это рекомендуемый режим для:
- UI-разработки;
- unit tests;
- Personal Team;
- отладки без Apple Developer Program.

## CloudKit mode

CloudKit является опциональным.

Нужно:
1. иметь платную Apple Developer Team;
2. создать собственный CloudKit container;
3. заменить placeholder container ID в entitlements;
4. включить iCloud/CloudKit capabilities;
5. выставить `BalanceCloudKitEnabled=YES`.

Не смешивайте CloudKit и собственный сервер как два активных sync backends для одной пользовательской базы.

## Server mode

В Settings укажите URL сервера, затем зарегистрируйтесь или войдите.

Для физического устройства удалённый адрес должен быть HTTPS.

Для локального сервера допустим:

```text
http://localhost:...
http://127.0.0.1:...
```

На физическом iPhone `localhost` означает сам iPhone, а не Mac-разработчика.

## Экспорт CSV

CSV export реализован в:

```text
Balance/Views/Settings/CSVDocument.swift
```

Экспорт доступен на iOS и macOS.

## Troubleshooting

### Xcode использует старые build artifacts

```text
Product → Clean Build Folder
```

Если проблема сохраняется, удалите DerivedData проекта и заново откройте Xcode.

### SwiftData schema error

Проверьте изменения `@Model` и не меняйте persisted fields без migration strategy.

### Sync не работает

Проверьте по порядку:
1. server URL;
2. HTTPS/localhost rule;
3. авторизацию;
4. дату последней синхронизации;
5. cursor;
6. совместимость версии Balance Server.

### Данные не удаляются на другом устройстве

Проверьте, что удаление выполнено через `deleteForSync(...)`, а не прямой `delete(...)`.
