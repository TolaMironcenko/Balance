# AGENTS.md — корень монорепозитория Balance

Этот файл — точка входа для AI-агентов и разработчиков, работающих в
репозитории Balance. Он описывает, как устроены три подпроекта, как они
связаны друг с другом, и куда идти за подробностями. **Каждый подпроект
имеет собственный `AGENTS.md` с детальными правилами — читай его перед
любым изменением внутри соответствующей папки.**

## Что это за проект

Balance — приложение для учёта личных финансов, доступное на пяти
платформах, которые используют одну и ту же доменную модель и один и
тот же протокол синхронизации:

| Платформа | Папка | Стек |
| --- | --- | --- |
| iOS 17+ | `Balance/` | SwiftUI + SwiftData |
| macOS 14+ | `Balance/` (`BalanceMac/`) | SwiftUI + SwiftData |
| watchOS 10+ | `Balance/` (`BalanceWatch/`) | SwiftUI + SwiftData |
| Android 8.0+ | `BalanceAndroid/` | Kotlin + Jetpack Compose + Room |
| Web (встроен в сервер) | `BalanceServer/` | Go + embedded static client |
| Сервер синхронизации | `BalanceServer/` | Go + SQLite |

Все клиенты — iOS, macOS, watchOS, Android, web — синхронизируются через
один и тот же self-hosted сервер (`BalanceServer`) по единому HTTP(S)
API: регистрация, вход, refresh-токены, push/pull изменений с курсором,
tombstone-удаления, пользовательские категории и месячные бюджеты.

## Структура репозитория

```text
Balance/                    # монорепозиторий
├── AGENTS.md                # этот файл — общие правила для агентов
├── README.md                 # общий обзор и точки входа
├── docs/                     # сводная документация по всему проекту
│   ├── ARCHITECTURE.md       # как связаны клиенты и сервер
│   ├── SYNC_PROTOCOL.md      # единый протокол синхронизации
│   ├── DATA_MODEL.md         # сопоставление сущностей между платформами
│   ├── SECURITY.md           # сквозные требования безопасности
│   └── DEVELOPMENT.md        # как собрать и проверить все три проекта
│
├── Balance/                  # Xcode-проект: iOS + macOS + watchOS
│   ├── AGENTS.md              # правила для Apple-клиента
│   ├── README.md
│   └── docs/                  # ARCHITECTURE, DATA_MODEL, SYNC, DEVELOPMENT, PRODUCT
│
├── BalanceAndroid/           # Android-проект (Gradle/Kotlin)
│   ├── AGENTS.md              # правила для Android-клиента
│   ├── README.md
│   └── docs/                  # ARCHITECTURE, DATA_MODEL, SYNC, DEVELOPMENT, PRODUCT
│
└── BalanceServer/            # Go-сервер синхронизации + web-клиент
    ├── AGENTS.md              # правила для сервера
    ├── README.md
    └── docs/                  # ARCHITECTURE, API, DATA_MODEL, SYNC, SECURITY, DEVELOPMENT, DEPLOYMENT, PRODUCT
```

## Как работать в этом репозитории

### 1. Сначала пойми, в каком подпроекте изменение

Каждый подпроект — независимый билд с собственными зависимостями,
тестами и CI-шагами. Изменения в одной папке не должны требовать
правок в другой, **кроме** случаев, когда меняется общий контракт:

- HTTP API / формат sync-запросов и ответов (`BalanceServer`);
- набор синхронизируемых полей сущности (транзакция, категория, бюджет);
- правила финансовых расчётов (баланс, корректировки, аналитика).

Если меняется общий контракт — обнови все три подпроекта согласованно
и синхронизируй документацию (`docs/SYNC_PROTOCOL.md`, а также
`docs/SYNC.md`/`docs/API.md`/`docs/DATA_MODEL.md` внутри каждой папки).

### 2. Единая доменная модель

Три клиента независимо реализуют одну и ту же модель на своём стеке
(SwiftData / Room), но со семантически одинаковыми сущностями:

- **Транзакция** (доход/расход, сумма, дата, заметка, категория —
  хранится snapshot'ом имени/иконки/цвета категории на момент операции);
- **Пользовательская категория** (имя, иконка/emoji, цвет);
- **Месячный бюджет** (категория, месяц, лимит);
- **Tombstone/deletion journal** для распространения удалений между
  устройствами.

Общие правила расчётов (баланс = доходы − расходы; корректировки
баланса учитываются в общем балансе, но не в периодической аналитике;
расходы группируются по имени категории) продублированы в:

- `Balance/Balance/Utilities/FinanceCalculations.swift` (Apple);
- `BalanceAndroid/.../data/FinanceMath.kt` (Android).

При изменении этих правил на одной платформе — переноси изменение на
другую и обновляй оба набора тестов
(`BalanceTests/FinanceCalculationsTests.swift`, `FinanceMathTest`).

### 3. Синхронизация — общий контракт

Единый протокол описан в `docs/SYNC_PROTOCOL.md` (сводно) и подробно —
в `BalanceServer/docs/API.md` и `BalanceServer/docs/SYNC.md`. Клиентские
реализации:

- Apple: `Balance/Balance/Shared/ServerSync.swift`;
- Android: `BalanceAndroid/.../sync/SyncRepository.kt`.

Изменение cursor/sequence semantics, JSON-полей или auth-заголовков —
breaking change для всех клиентов сразу. Не меняй его в одном
подпроекте, не проверив остальные два.

### 4. Безопасность (сквозные требования)

- Секреты (пароли, access/refresh токены) никогда не хранятся в
  открытом виде: Keychain (Apple), Android Keystore + AES/GCM
  (Android), Argon2id-хеши + SHA-256 refresh-token хеши (сервер).
- HTTPS обязателен для удалённого сервера на всех клиентах; HTTP
  разрешён только для `localhost`/`127.0.0.1`/`::1`.
- Не логируй пароли, токены или заголовок `Authorization` ни в одном
  из подпроектов.
- Не коммить секреты, production-URL или credentials.

Подробности — `docs/SECURITY.md` и `BalanceServer/docs/SECURITY.md`.

### 5. Тестирование перед PR

Запусти проверки для всех подпроектов, которые ты менял:

```bash
# Apple (из Balance/)
xcodebuild -project Balance.xcodeproj -scheme Balance \
  -destination 'platform=iOS Simulator,name=<available iPhone>' test

# Android (из BalanceAndroid/)
./gradlew clean test assembleDebug

# Server (из BalanceServer/)
go test ./...
go vet ./...
go build ./...
```

Если менялся общий контракт (API/sync/data model) — прогони проверки
во всех трёх, а не только в изменённой папке.

### 6. Документация

- Меняешь контракт синхронизации → обнови `docs/SYNC_PROTOCOL.md` в
  корне **и** `BalanceServer/docs/SYNC.md`/`API.md`, а также
  `docs/SYNC.md` в `Balance/` и `BalanceAndroid/`.
- Меняешь модель данных на любой платформе → обнови `docs/DATA_MODEL.md`
  в корне и в затронутом подпроекте.
- Меняешь способ сборки/запуска → обнови `docs/DEVELOPMENT.md` в
  корне и соответствующий `README.md`/`docs/DEVELOPMENT.md` подпроекта.
- Каждый подпроект содержит собственный подробный `AGENTS.md` — этот
  файл не заменяет их, а даёт общую картину и правила координации между
  платформами.

## PR checklist (для изменений, затрагивающих несколько платформ)

- [ ] Определены все подпроекты, которые затрагивает изменение.
- [ ] Общий контракт (API/sync/data model) обновлён согласованно во
      всех платформах, а не только в одной.
- [ ] Финансовые расчёты остаются идентичными на Apple и Android.
- [ ] Обновлены `docs/SYNC_PROTOCOL.md`, `docs/DATA_MODEL.md` в корне,
      если менялась схема/протокол.
- [ ] Секреты и токены не добавлены в репозиторий ни в одном подпроекте.
- [ ] Тесты пройдены в каждом изменённом подпроекте.
- [ ] Локальный `AGENTS.md` соответствующего подпроекта тоже соблюдён.
