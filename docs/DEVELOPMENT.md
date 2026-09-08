# Разработка (все платформы)

Сводная шпаргалка по сборке, запуску и проверке всех трёх подпроектов.
Подробности — в `docs/DEVELOPMENT.md` каждого подпроекта.

## Требования по платформам

| Подпроект | Инструменты | Минимальные версии |
| --- | --- | --- |
| `Balance/` | Xcode, Swift | Xcode 16+, iOS 17+, macOS 14+, watchOS 10+ |
| `BalanceAndroid/` | Android Studio / Gradle | AGP 8.13, Kotlin 2.3.21, compileSdk 36, minSdk 26, Java 17 |
| `BalanceServer/` | Go | Go 1.25.0+ |

## Локальный запуск всей системы

Порядок, удобный для end-to-end проверки sync между платформами:

```bash
# 1. Поднять сервер
cd BalanceServer
cp .env.example .env
# задать BALANCE_JWT_SECRET (см. README.md)
go mod tidy
go run ./cmd/balance-server
# сервер слушает http://localhost:8080

# 2. Открыть Apple-проект и указать http://localhost:8080 в Settings → Server account
cd ../Balance
open Balance.xcodeproj

# 3. Собрать и запустить Android-приложение
cd ../BalanceAndroid
./gradlew assembleDebug
# на эмуляторе сервер локального хоста доступен как http://10.0.2.2:8080
```

Для физического iPhone/Android-устройства `localhost` указывает на само
устройство, а не на машину разработчика — используйте сетевой адрес
или HTTPS reverse proxy (см. `docs/SECURITY.md`).

## Сборка и тесты по отдельности

### Apple (`Balance/`)

```bash
xcodebuild -project Balance.xcodeproj -list

xcodebuild -project Balance.xcodeproj -scheme Balance \
  -destination 'generic/platform=iOS' build

xcodebuild -project Balance.xcodeproj -scheme Balance \
  -destination 'platform=iOS Simulator,name=<available iPhone>' test
```

Схемы: `Balance` (iOS), `BalanceMac`, `BalanceWatch`. Без
`BalanceCloudKitEnabled=YES` приложение работает в local-mode
(SwiftData без CloudKit) — рекомендуемый режим для разработки.

### Android (`BalanceAndroid/`)

```bash
./gradlew clean test assembleDebug
```

Тесты — `app/src/test/FinanceMathTest`. `local.properties` с `sdk.dir`
не должен попадать в Git.

### Server (`BalanceServer/`)

```bash
go mod download
go test ./...
go test -race ./...
go vet ./...
go build ./...
```

Docker-путь — `docker compose up -d --build` (см.
[`BalanceServer/README.md`](../BalanceServer/README.md)).

## Что проверять при изменении общего контракта

Если PR меняет sync API, модель данных или финансовые расчёты — прогони
проверки во всех трёх подпроектах, а не только в изменённом:

```text
old iOS client   + new server
new iOS client   + server
Android client   + server
concurrent sync с двух устройств одного аккаунта
login/refresh после истечения access token
delete → pull на другом устройстве
```

## Типовые проблемы синхронизации (одинаковый чек-лист для обеих платформ)

1. Проверь server URL в настройках клиента.
2. Проверь правило HTTPS/localhost (см. `docs/SECURITY.md`).
3. Проверь авторизацию/сессию (login, не истёк ли refresh).
4. Проверь дату последней синхронизации и сохранённый cursor.
5. Проверь совместимость версии клиента и `BalanceServer`.
6. Если данные не удаляются на другом устройстве — убедись, что
   удаление прошло через tombstone-путь
   (`modelContext.deleteForSync` на Apple,
   `FinanceDao.deleteTransaction/deleteCategory/deleteBudget` на
   Android), а не через прямой `delete()`.
