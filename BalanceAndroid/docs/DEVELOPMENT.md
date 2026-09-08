# Разработка

## Toolchain

Текущая версия проекта:

- Android Studio Quail 1 (2026.1.1) или новее
- Gradle 8.13
- Android Gradle Plugin 8.13.0
- Kotlin 2.3.21
- Compose BOM 2026.06.00
- compileSdk 36
- minSdk 26
- Java 17 target
- Room 2.8.4
- Lifecycle 2.10.0

Проект не использует сторонние runtime-библиотеки вне стандартного Android/Jetpack stack.

## Запуск

Откройте `BalanceAndroid/` в Android Studio.

Затем:

1. Gradle Sync.
2. Установить Android SDK Platform 36.
3. Создать/подключить Android 8+ устройство или emulator.
4. Запустить configuration `app`.

## CLI

```bash
./gradlew test assembleDebug
```

Полная чистая проверка:

```bash
./gradlew clean test assembleDebug
```

Проверить JVM:

```bash
./gradlew --version
```

Используется Java 17–23; bytecode target — Java 17.

## SDK

Можно использовать:

```bash
export ANDROID_HOME="/path/to/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
```

или `local.properties`:

```properties
sdk.dir=/home/USER/Android/Sdk
```

`local.properties` не должен попадать в Git.

## Unit tests

Тесты находятся в:

```text
app/src/test/
```

Основной текущий тестовый класс:

```text
FinanceMathTest
```

Тестируй отдельно:
- balance;
- period summary;
- adjustment exclusion;
- spending grouping;
- edge cases around period boundaries.

## Local development

Приложение работает без сервера. Локальные данные хранятся в Room.

Для Android Emulator host server:

```text
http://10.0.2.2:8080
```

Для физического Android device `localhost` указывает на сам телефон, поэтому нужен доступный по сети HTTPS endpoint.

## Application ID

Текущий пример:

```text
com.example.balanceandroid
```

Перед Google Play release замени его на уникальный production application ID.

## Release checklist

- [ ] Production applicationId.
- [ ] Release signing key.
- [ ] HTTPS server.
- [ ] Проверен backup/data extraction policy.
- [ ] Проверена миграция Room.
- [ ] Проверена background sync.
- [ ] Проверена авторизация и token refresh.
- [ ] Нет секретов в APK source/config.
- [ ] `./gradlew clean test assembleDebug` проходит.

## Troubleshooting

### Gradle не находит SDK

Проверь `ANDROID_HOME`, `ANDROID_SDK_ROOT` или `local.properties`.

### Неверная Java

Android Studio → Gradle JDK → Embedded JDK.

Нужна Java 17–23.

### Старый Gradle daemon

```bash
./gradlew --stop
./gradlew clean test assembleDebug
```

### Sync не работает

Проверь:
1. server URL;
2. HTTPS/local HTTP rule;
3. login/session;
4. network connection;
5. cursor/lastPush;
6. совместимость BalanceServer protocol.

### Данные не удаляются на другом устройстве

Убедись, что вызывается `FinanceDao.deleteTransaction/deleteCategory/deleteBudget`, а не `delete*Direct`.
