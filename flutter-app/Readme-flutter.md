# HRleaders Flutter — руководство разработчика и выпуск приложения

Документ описывает установку инструментов, настройку проекта, запуск, сборку,
тестирование, публикацию Web-приложения в Firebase Hosting и подготовку Android
App Bundle для Google Play.

Все команды ниже запускаются из корневой папки Flutter-проекта
`hr-flutter-app`. В PowerShell перейти в неё можно так:

```powershell
Set-Location hr-flutter-app
```

## 1. Необходимые инструменты

- Flutter SDK версии не ниже, указанной в `pubspec.yaml` (сейчас `>=3.47.0`).
- Совместимый Dart SDK, устанавливаемый вместе с Flutter (ограничение проекта:
  `>=3.13.0 <4.0.0`).
- Git и доступ к pub.dev для загрузки пакетов.
- Для Web: Chrome или другой браузер.
- Для Android: Android Studio или Android SDK Command-line Tools, JDK 17,
  Android SDK и эмулятор либо устройство с включённой USB-отладкой.
- Для публикации: Firebase CLI; для Google Play — аккаунт Google Play Console.

Проверьте установку и доступность Android toolchain:

```powershell
flutter --version
dart --version
flutter doctor -v
```

В Android Studio откройте **SDK Manager** и установите Android SDK Platform,
Build-Tools и Command-line Tools, предлагаемые установленной версией Flutter.
Затем примите лицензии:

```powershell
flutter doctor --android-licenses
```

`flutter doctor -v` должен показывать установленный Flutter SDK, Android
toolchain и подходящее устройство. Для настройки Android SDK или лицензий
используйте путь, который выводит `flutter doctor`.

## 2. Установка и конфигурация проекта

Установите зависимости из зафиксированного lock-файла:

```powershell
flutter pub get --enforce-lockfile
```

Параметры приложения:

- Переводы находятся в `lib/core/localization/arb/`.
- Сгенерированные файлы локализации находятся в
  `lib/core/localization/generated/`.
- Конфигурация генератора локализаций — `l10n.yaml`.
- Android application ID — `ru.hrleaders.hrleaders`
  (`android/app/build.gradle.kts`).
- Версия приложения и номер сборки задаются в `pubspec.yaml`; исходное значение
  — `0.1.0+1`.
- Изображения и остальные Flutter assets объявляются в секции `flutter.assets`
  файла `pubspec.yaml`.

После изменения строк в ARB-файлах пересоздайте локализации:

```powershell
flutter gen-l10n
```

По умолчанию приложение запускается в демонстрационном режиме с локальными
данными в памяти. Демонстрационные учётные записи: `candidate`,
`hr`, `admin`, `analyst`, `superadmin` с адресом
`<role>@demo.hrleaders.example` и паролем `Demo12345`. Не используйте их для
боевого сервиса. Mock-данные исчезают при перезапуске приложения.

Для подключения к существующему API явно выключите demo-режим:

```powershell
flutter run `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

Указывайте базовый URL API с завершающим `/`. Для Web допустим относительный
URL, например `/api/v1/`, если сервер или Hosting настроен проксировать этот
путь. Для Android и iOS в live-режиме необходим абсолютный URL. Передавайте
адрес при запуске/сборке, а не храните production URL с credentials или
секретами в исходном коде.

## 3. Запуск приложения

### Web в Chrome

Демонстрационный режим:

```powershell
flutter run -d chrome
```

Live API:

```powershell
flutter run -d chrome `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=/api/v1/
```

Для Web live-режима API должен разрешать запросы с сайта либо обслуживаться
через тот же origin. Предпочтителен same-origin HTTPS и HttpOnly cookie,
настроенная сервером.

### Android

Убедитесь, что Android-устройство или эмулятор видны Flutter:

```powershell
flutter devices
```

Запустите demo на подключённом устройстве:

```powershell
flutter run -d <device-id>
```

Live API на Android:

```powershell
flutter run -d <device-id> `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

В эмуляторе Android `localhost` указывает на сам эмулятор, а не на компьютер
разработчика; используйте адрес хоста, доступный из эмулятора.

## 4. Анализ, форматирование и тестирование

Форматирование Dart-кода:

```powershell
dart format lib test
```

Проверка форматирования без изменения файлов:

```powershell
dart format --output=none --set-exit-if-changed lib test
```

Статический анализ:

```powershell
flutter analyze
```

Все автоматические тесты:

```powershell
flutter test
```

Тесты с отчётом покрытия:

```powershell
flutter test --coverage
```

Запуск отдельных тестов:

```powershell
flutter test test\assessment_flow_test.dart
flutter test test\cjm_flow_test.dart
flutter test test\recruiter_cjm_flow_test.dart
flutter test test\recruiter_cjm_widget_test.dart
flutter test test\remote_assessment_repository_test.dart
flutter test test\remote_recruiter_cjm_repository_test.dart
```

Базовые release-сборки:

```powershell
flutter build web --release
flutter build apk --release
```

Для публикации используйте приведённые ниже команды с production URL и
корректной подписью, а не собирайте live-приложение в demo-режиме.

## 5. Сборка Web

Демо-сборка:

```powershell
flutter build web --release `
  --dart-define=HRLEADERS_DEMO=true `
  --output=build\web-demo
```

Live-сборка для same-origin API:

```powershell
flutter build web --release `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=/api/v1/ `
  --output=build\web
```

Результат — статические файлы в `build\web`. Для production API настройте HTTPS,
same-origin проксирование `/api/v1/` на backend и правила SPA fallback на
`index.html`. Например, для собственного Nginx-прокси исходный вариант
находится в `deploy\nginx.conf`. Firebase Hosting настраивается отдельно —
см. следующий раздел.

## 6. Публикация Web-приложения в Firebase Hosting

В проекте пока нет `firebase.json` и конфигурации Firebase Hosting. Для
публикации потребуется Firebase project и выбранная схема подключения API.
Firebase CLI настраивается на компьютере разработчика или в CI:

```powershell
npm install -g firebase-tools
firebase login
firebase projects:list
```

Создайте Firebase project в Firebase Console либо выберите существующий.
Из корня Flutter-проекта запустите первоначальную настройку:

```powershell
firebase init hosting
```

Выберите нужный Firebase project, публичную директорию `build\web`, настройте
SPA rewrite на `/index.html`. Не разрешайте CLI перезаписать существующее
приложение `index.html`, если оно уже появилось в `web/`. Инициализация создаст
`firebase.json` (и, в зависимости от выбора, `.firebaserc`); проверьте и
закоммитьте безопасную конфигурацию проекта.

Минимальный пример `firebase.json` для SPA без backend rewrite:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

Соберите и предварительно проверьте результат:

```powershell
flutter build web --release `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=/api/v1/
firebase emulators:start --only hosting
```

Для live-режима одного SPA rewrite недостаточно: Firebase Hosting должен
направлять `/api/**` к backend (например, в Cloud Run) **до** правила SPA
fallback. Пример rewrite на Cloud Run — замените сервис и регион на реальные:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "/api/**",
        "run": {
          "serviceId": "hrleaders-api",
          "region": "europe-west1"
        }
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

Если backend размещён не в Cloud Run, настройте подходящий Firebase Hosting
rewrite на поддерживаемую инфраструктуру или соберите клиент с полным
HTTPS `API_BASE_URL`. В последнем варианте backend должен разрешать origin
Firebase, корректно выдавать cookie с нужными `SameSite`/`Secure` атрибутами и
принимать credentialed CORS-запросы; HttpOnly cookie и CORS должны быть
проверены отдельно. Не перенаправляйте `/api/**` в `index.html`.

Опубликуйте Hosting:

```powershell
firebase deploy --only hosting
```

Для отдельного preview channel:

```powershell
firebase hosting:channel:deploy preview
```

Перед production-деплоем проверьте выбранный project командой
`firebase use` / `firebase projects:list`, HTTPS, прямое открытие вложенных
маршрутов, авторизацию, обновление страницы, API-запросы и отсутствие
демонстрационных данных.

## 7. Подготовка Android к магазину

### 7.1. Проверьте идентификатор и версию

Application ID сборки сейчас — `ru.hrleaders.hrleaders`; его задаёт
`applicationId` в `android\app\build.gradle.kts`. Выберите окончательный
уникальный ID до первой публикации: после публикации в Google Play нельзя
заменить package name существующего приложения.

В `pubspec.yaml` версия имеет формат:

```yaml
version: 1.2.3+45
```

Часть до `+` становится `versionName`, число после `+` — `versionCode`.
Увеличивайте `versionCode` для каждой новой публикации и сверяйте требования
Google Play к target SDK непосредственно перед релизом; проект задаёт
`targetSdk` через Flutter Gradle plugin.

### 7.2. Создайте upload keystore и настройте release signing

**Текущая конфигурация проекта подписывает release debug-ключом. Это подходит
для локальной проверки, но не для Google Play. До публикации обязательно
настройте собственную release-подпись.** Никогда не публикуйте keystore,
пароли или `key.properties` в репозитории.

Сгенерируйте upload keystore в защищённом месте вне репозитория. `keytool`
поставляется с JDK:

```powershell
keytool -genkey -v `
  -keystore "$HOME\hrleaders-upload-key.jks" `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload
```

Храните резервную копию keystore и пароли в защищённом хранилище с ограниченным
доступом. Потеря ключа может усложнить выпуск обновлений; используйте
Play App Signing и сохраняйте upload key в безопасном месте.

Создайте файл `android\key.properties` (не коммитьте его):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/YOUR_USER/hrleaders-upload-key.jks
```

В `android\app\build.gradle.kts` подключите свойства перед блоком `android`:

```kotlin
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use(keystoreProperties::load)
}
```

Внутри блока `android { ... }` добавьте release signing config:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}
```

В существующем `buildTypes { release { ... } }` замените debug signing:

```kotlin
signingConfig = signingConfigs.getByName("release")
```

На CI передавайте секреты через защищённые secret variables и временно
создавайте `key.properties`/keystore в процессе сборки; не печатайте их
содержимое в лог.

### 7.3. Соберите и проверьте артефакты

Google Play предпочитает Android App Bundle (`.aab`); APK удобен для ручной
установки и проверки. Для live-приложения задайте API URL:

```powershell
flutter clean
flutter pub get --enforce-lockfile
flutter analyze
flutter test

flutter build appbundle --release `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

Основной bundle будет создан по пути:

```text
build\app\outputs\bundle\release\app-release.aab
```

Для локальной установки APK:

```powershell
flutter build apk --release `
  --dart-define=HRLEADERS_DEMO=false `
  --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

Артефакт находится в `build\app\outputs\flutter-apk\app-release.apk`.
Установите APK на тестовое устройство и проверьте запуск, вход, сетевое
соединение, возврат после сворачивания, deep link `hrleaders://` и светлую/
тёмную темы. Для bundle загрузите `.aab` в Internal testing track Google Play
Console и проверьте сгенерированный Play APK на реальных устройствах.

### 7.4. Загрузка в Google Play Console

1. Создайте приложение в Google Play Console и укажите точное название,
   язык, application ID, тип и бесплатный/платный статус.
2. Настройте Play App Signing; загрузите release `.aab`, подписанный вашим
   upload key.
3. Заполните обязательные карточку магазина, графические материалы,
   классификацию контента, сведения о доступе/тестовой учётной записи,
   Data safety и ссылку на политику конфиденциальности.
4. Выпустите Internal testing, проверьте установку и ключевые сценарии,
   устраните ошибки pre-launch report.
5. Увеличьте номер сборки, соберите и загрузите следующую версию в нужный
   testing/production track и отправьте её на проверку Google Play.

Проверьте актуальные правила Play Console — требования к целевому API,
политике конфиденциальности, Data safety, тестированию и подписанию могут
обновляться независимо от Flutter.

## 8. Частые проблемы

- **Зависимости расходятся с lock-файлом:** проверьте Flutter/Dart SDK и
  используйте `flutter pub get --enforce-lockfile`.
- **Новые локализационные getter-ы не найдены:** выполните
  `flutter gen-l10n`.
- **Live-режим не может подключиться:** убедитесь, что
  `HRLEADERS_DEMO=false`, `API_BASE_URL` заканчивается на `/`, backend доступен
  по HTTPS, а Web CORS/cookie настроены для правильного origin.
- **Для Android native `API_BASE_URL` задан относительно:** используйте
  абсолютный `https://.../api/v1/` URL.
- **Прямой URL Web-маршрута возвращает 404:** добавьте SPA rewrite на
  `/index.html`, сохранив отдельное правило для `/api/**`.
- **Google Play отклоняет bundle по подписи:** убедитесь, что release использует
  собственный upload keystore, а не debug key, и что application ID совпадает
  с созданным приложением.
- **Устройство не отображается:** выполните `flutter doctor -v`, проверьте
  Android SDK, USB-отладку, кабель и вывод `flutter devices`.
