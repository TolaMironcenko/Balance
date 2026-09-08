# Balance — все платформы

Balance — приложение для учёта личных финансов с нативными клиентами
для iOS, macOS, watchOS, Android и встроенным web-интерфейсом, а также
self-hosted сервер синхронизации на Go. В архиве находится
монорепозиторий из трёх независимо собираемых проектов.

| Папка | Назначение | Стек |
| --- | --- | --- |
| [`Balance/`](Balance/README.md) | iOS 17+, macOS 14+ и watchOS 10+ | SwiftUI + SwiftData |
| [`BalanceAndroid/`](BalanceAndroid/README.md) | Android 8.0+ | Kotlin + Jetpack Compose + Room |
| [`BalanceServer/`](BalanceServer/README.md) | Go-сервер авторизации, синхронизации и встроенный web-клиент | Go + SQLite |

Все пять клиентов — iOS, macOS, watchOS, Android и web — используют
одну модель данных и один протокол сервера: операции, пользовательские
категории, бюджеты, удаления, регистрация, вход, refresh-токены и
постраничная двусторонняя синхронизация. Web-интерфейс открывается по
адресу запущенного сервера и не требует отдельной установки.

## Быстрый старт

1. **Поднять сервер** — см. [`BalanceServer/README.md`](BalanceServer/README.md#quick-start-with-docker)
   (Docker или локальная сборка Go-бинарника).
2. **Открыть Apple-проект** — `open Balance/Balance.xcodeproj`, см.
   [`Balance/README.md`](Balance/README.md).
3. **Собрать Android-приложение** — `cd BalanceAndroid && ./gradlew assembleDebug`,
   см. [`BalanceAndroid/README.md`](BalanceAndroid/README.md).
4. В любом клиенте укажите адрес запущенного сервера в настройках
   аккаунта, чтобы включить синхронизацию между устройствами.

## Документация

Документация организована на двух уровнях:

- **Корневой уровень** (`docs/`) — то, что относится ко всем платформам
  сразу: как устроена система в целом, единый протокол синхронизации,
  сквозная модель данных и требования безопасности.
- **Уровень подпроекта** (`Balance/docs/`, `BalanceAndroid/docs/`,
  `BalanceServer/docs/`) — детали конкретной платформы: код, схемы,
  сборка, деплой.

| Документ | Описание |
| --- | --- |
| [`AGENTS.md`](AGENTS.md) | Правила для AI-агентов и разработчиков, работающих во всём репозитории |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Как связаны клиенты и сервер, общая схема системы |
| [`docs/SYNC_PROTOCOL.md`](docs/SYNC_PROTOCOL.md) | Единый протокол синхронизации между всеми клиентами и сервером |
| [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) | Сопоставление доменных сущностей между платформами |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Сквозные требования безопасности (токены, HTTPS, хранение секретов) |
| [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) | Как собрать, запустить и протестировать все три проекта |

### Документация по подпроектам

- **Apple (`Balance/`):** [`AGENTS.md`](Balance/AGENTS.md) ·
  [`docs/ARCHITECTURE.md`](Balance/docs/ARCHITECTURE.md) ·
  [`docs/DATA_MODEL.md`](Balance/docs/DATA_MODEL.md) ·
  [`docs/SYNC.md`](Balance/docs/SYNC.md) ·
  [`docs/DEVELOPMENT.md`](Balance/docs/DEVELOPMENT.md) ·
  [`docs/PRODUCT.md`](Balance/docs/PRODUCT.md)
- **Android (`BalanceAndroid/`):** [`AGENTS.md`](BalanceAndroid/AGENTS.md) ·
  [`docs/ARCHITECTURE.md`](BalanceAndroid/docs/ARCHITECTURE.md) ·
  [`docs/DATA_MODEL.md`](BalanceAndroid/docs/DATA_MODEL.md) ·
  [`docs/SYNC.md`](BalanceAndroid/docs/SYNC.md) ·
  [`docs/DEVELOPMENT.md`](BalanceAndroid/docs/DEVELOPMENT.md) ·
  [`docs/PRODUCT.md`](BalanceAndroid/docs/PRODUCT.md)
- **Server (`BalanceServer/`):** [`AGENTS.md`](BalanceServer/AGENTS.md) ·
  [`docs/ARCHITECTURE.md`](BalanceServer/docs/ARCHITECTURE.md) ·
  [`docs/API.md`](BalanceServer/docs/API.md) ·
  [`docs/DATA_MODEL.md`](BalanceServer/docs/DATA_MODEL.md) ·
  [`docs/SYNC.md`](BalanceServer/docs/SYNC.md) ·
  [`docs/SECURITY.md`](BalanceServer/docs/SECURITY.md) ·
  [`docs/DEVELOPMENT.md`](BalanceServer/docs/DEVELOPMENT.md) ·
  [`docs/DEPLOYMENT.md`](BalanceServer/docs/DEPLOYMENT.md) ·
  [`docs/PRODUCT.md`](BalanceServer/docs/PRODUCT.md)

## Структура репозитория

```text
Balance/
├── AGENTS.md              # общие правила для агентов по всему репо
├── README.md               # этот файл
├── docs/                   # сводная документация по всем платформам
├── Balance/                 # Xcode-проект: iOS + macOS + watchOS
├── BalanceAndroid/          # Android (Gradle/Kotlin)
└── BalanceServer/           # Go-сервер + встроенный web-клиент
```
