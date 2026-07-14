# Баланс для Android

Нативное Android-приложение личных финансов в дизайне основного проекта Balance. Написано на Kotlin и Jetpack Compose, использует Room для локального хранения и тот же self-hosted Go-сервер для синхронизации с iOS, macOS и watchOS.

## Возможности

- доходы, расходы, поиск, фильтрация, добавление, редактирование и удаление операций;
- общий баланс и ручная корректировка, не влияющая на аналитику;
- аналитика за месяц, 3 и 12 месяцев, структура расходов и норма сбережений;
- месячные бюджеты;
- собственные категории, 50 вариантов иконок, ввод эмодзи, 30 готовых эмодзи и палитра из 24 цветов;
- светлая, тёмная и системная тема;
- RUB, EUR, USD и SEK;
- локальная работа без сервера;
- указание и смена сервера, регистрация, вход, выход и полная пересинхронизация;
- пакетная двусторонняя синхронизация операций, категорий, бюджетов и удалений;
- access/refresh-токены шифруются ключом Android Keystore;
- фоновая синхронизация через WorkManager раз в 15 минут при наличии сети.

## Запуск

1. Откройте папку `BalanceAndroid` в Android Studio Quail 1 (2026.1.1) или новее.
2. Дождитесь Gradle Sync и установки Android SDK 36.
3. Запустите конфигурацию `app` на устройстве с Android 8.0 (API 26) или новее.

Для запуска Gradle проекту нужен JDK 17–23; байткод собирается с целевым уровнем Java 17. Используются Gradle 8.13, AGP 8.13.0, Kotlin 2.3.21 и Compose BOM 2026.06.00.

Kotlin и Compose compiler plugin закреплены на 2.3.21, потому что стабильный Room 2.8.4 поддерживает Kotlin metadata до версии 2.3. Обновлять Kotlin до 2.4 можно после выхода совместимой стабильной версии Room.

Lifecycle закреплён на ветке 2.10.0, совместимой с compileSdk 36 и AGP 8.13. Lifecycle 2.11 требует API 37 и AGP 9.1, поэтому не обновляйте эти две зависимости отдельно без одновременного перехода всего проекта на новый Android toolchain.

Перед публикацией в Google Play замените примерный `applicationId` `com.example.balanceandroid` в `app/build.gradle.kts` на собственный уникальный идентификатор.

## Подключение сервера

Откройте **Настройки → Сервер и синхронизация**, введите адрес и сохраните его, затем зарегистрируйтесь или войдите. На эмуляторе сервер, запущенный на компьютере, доступен по адресу:

```text
http://10.0.2.2:8080
```

Для физического устройства используйте HTTPS. Незащищённый HTTP разрешён только для `localhost`, `127.0.0.1` и специального адреса Android Emulator `10.0.2.2`.

Android совместим с протоколом `BalanceServer` 3.1. Сервер из общего архива менять не нужно.

## Сборка из командной строки

Скрипт автоматически ищет SDK в переменных `ANDROID_HOME`/`ANDROID_SDK_ROOT` и стандартных каталогах:

- Linux: `$HOME/Android/Sdk`;
- macOS: `$HOME/Library/Android/sdk`;
- Windows: `%LOCALAPPDATA%\Android\Sdk`.

После установки Android SDK 36 выполните:

```sh
./gradlew test assembleDebug
```

Если SDK ещё не установлен, откройте **Tools → SDK Manager** и установите **Android SDK Platform 36**, **Android SDK Build-Tools** и **Android SDK Platform-Tools**. Путь указан в верхней строке `Android SDK Location`.

Для нестандартного пути на Linux или macOS:

```sh
export ANDROID_HOME="/путь/к/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
./gradlew test assembleDebug
```

Вместо переменных можно создать файл `BalanceAndroid/local.properties`:

```properties
sdk.dir=/home/USER/Android/Sdk
```

На macOS скрипт автоматически использует JBR из стандартной установки Android Studio, если `JAVA_HOME` указывает на устаревшую Java 8. Проверить активную версию можно командой `./gradlew --version` — в строке `Launcher JVM` должна быть Java 17–23.

Если Android Studio установлена в нестандартную папку, задайте её JBR вручную:

```sh
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew test assembleDebug
```

В Android Studio выберите **Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle JDK → Embedded JDK**.

Если ранее Gradle запускался с недостаточной памятью, остановите старый daemon перед повторной сборкой:

```sh
./gradlew --stop
./gradlew clean test assembleDebug
```

Проект задаёт для Gradle 2 ГБ heap, 1 ГБ metaspace и не более двух параллельных workers. Эти параметры находятся в `gradle.properties` и применяются также при сборке из Android Studio.

Debug APK появится в `app/build/outputs/apk/debug/`.
