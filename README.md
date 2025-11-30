# gms_services

Flutter плагин для работы с Google Mobile Services.

## Установка

Добавьте зависимость в ваш `pubspec.yaml`:

```yaml
dependencies:
  gms_services: ^0.0.1
```

## Настройка Android

Для работы плагина необходимо настроить Google Services и Firebase Crashlytics в вашем Android проекте. Настройка выполняется автоматически.

### Автоматическая настройка

Плагин автоматически настроит необходимые конфигурации Gradle. Выполните в корне вашего Flutter проекта:

```bash
flutter pub get
dart run gms_services:setup
```

Скрипт автоматически:
- ✅ Добавит Google Services и Firebase Crashlytics плагины в `android/settings.gradle.kts`
- ✅ Применит плагины в `android/app/build.gradle.kts`

**После настройки:**
1. Добавьте файл `google-services.json` в папку `android/app/` (если его еще нет)
2. Пересоберите проект: `flutter clean && flutter pub get`

### Удаление настроек

Если необходимо удалить настройки Google Services из проекта:

```bash
dart run gms_services:cleanup
```

Скрипт автоматически:
- ✅ Удалит Google Services и Firebase Crashlytics плагины из `android/settings.gradle.kts`
- ✅ Удалит применение плагинов из `android/app/build.gradle.kts`

### Используемые версии

Плагин автоматически настроит следующие версии:
- Google Services: `4.4.2`
- Firebase Crashlytics: `3.0.2`

## Использование

```dart
import 'package:gms_services/gms_services.dart';

// Ваш код здесь
```

## Лицензия

См. файл LICENSE.
