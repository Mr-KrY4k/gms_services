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
- ✅ Добавит необходимые зависимости в блок `dependencies` в `android/app/build.gradle.kts`
- ✅ Добавит настройку иконки уведомлений Firebase в `android/app/src/main/AndroidManifest.xml`

**После настройки:**
1. Добавьте файл `google-services.json` в папку `android/app/` (если его еще нет)
2. Добавьте иконку для уведомлений Firebase: создайте файл `android/app/src/main/res/drawable/firebase_icon_push.png` (или используйте существующую иконку)
3. Пересоберите проект: `flutter clean && flutter pub get`

### Удаление настроек

Если необходимо удалить настройки Google Services из проекта:

```bash
dart run gms_services:cleanup
```

Скрипт автоматически:
- ✅ Удалит Google Services и Firebase Crashlytics плагины из `android/settings.gradle.kts`
- ✅ Удалит применение плагинов из `android/app/build.gradle.kts`
- ✅ Удалит зависимости, добавленные плагином, из блока `dependencies`
- ✅ Удалит настройки Firebase из `android/app/src/main/AndroidManifest.xml`

### Используемые версии

Плагин автоматически настроит следующие версии:
- Google Services: `4.4.2`
- Firebase Crashlytics: `3.0.2`
- Play Services Location: `21.3.0`
- Install Referrer: `2.2`

## Программное использование API

Если вы хотите использовать функции setup и cleanup программно из другого плагина или приложения:

```dart
import 'package:gms_services/gms_services_setup.dart';

// Настройка Android проекта
final setupResult = await setupGmsServices();
if (setupResult.changesMade) {
  print('Настройка завершена!');
  for (final message in setupResult.messages) {
    print(message);
  }
}

// Удаление настроек
final cleanupResult = await cleanupGmsServices();
if (cleanupResult.changesMade) {
  print('Настройки удалены!');
  for (final message in cleanupResult.messages) {
    print(message);
  }
}

// Можно указать путь к проекту явно
final result = await setupGmsServices(
  projectRoot: '/path/to/your/flutter/project',
);
```

Это особенно полезно, если вы создаете другой плагин, который должен автоматически настраивать gms_services для пользователя.

## Использование

### Инициализация всех сервисов

Главный сервис `GmsServices` предоставляет единую точку входа для инициализации всех адаптеров:

```dart
import 'package:gms_services/gms_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Firebase Core (обязательно перед использованием плагина)
  await Firebase.initializeApp();
  
  // Инициализация всех GMS сервисов
  final result = await GmsServices.instance.init(
    onPushBlocked: () {
      // Колбек вызывается при блокировке push-уведомлений
      print('Пользователь заблокировал уведомления');
    },
  );
  
  if (result.success) {
    print('Все сервисы успешно инициализированы');
  } else {
    print('Ошибки при инициализации: ${result.allErrors}');
    // Проверяем статус каждого сервиса
    print('Analytics: ${result.analytics}');
    print('Remote Config: ${result.remoteConfig}');
    print('Messaging: ${result.messaging}');
  }
  
  runApp(MyApp());
}
```

### Работа с Analytics

```dart
import 'package:gms_services/gms_services.dart';

// Получение идентификатора экземпляра приложения
final instanceId = await GmsServices.instance.analytics.appInstanceId;
print('App Instance ID: $instanceId');

// Или напрямую через адаптер
final instanceId = await Analytics.instance.appInstanceId;
```

### Работа с Remote Config

```dart
import 'package:gms_services/gms_services.dart';

// Получение значений из Remote Config
final value = GmsServices.instance.remoteConfig.getString('my_key');
final intValue = GmsServices.instance.remoteConfig.getInt('my_int_key');
final boolValue = GmsServices.instance.remoteConfig.getBool('my_bool_key');

// Получение всех значений
final allValues = GmsServices.instance.remoteConfig.getAll();

// Или напрямую через адаптер
final value = RemoteConfig.instance.getString('my_key');
```

### Работа с Messaging (Push-уведомления)

```dart
import 'package:gms_services/gms_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Получение FCM токена
final token = await GmsServices.instance.messaging.fcmToken;
print('FCM Token: $token');

// Подписка на входящие сообщения
GmsServices.instance.messaging.onMessageReceived.listen((RemoteMessage message) {
  print('Получено сообщение: ${message.messageId}');
  print('Заголовок: ${message.notification?.title}');
  print('Текст: ${message.notification?.body}');
});

// Подписка на изменение статуса уведомлений
GmsServices.instance.messaging.onNotificationStatusChanged.listen((status) {
  print('Статус уведомлений: $status');
});

// Получение всех сохраненных сообщений
final messages = GmsServices.instance.messaging.messages;

// Проверка, было ли приложение открыто через пуш
final wasOpenedByPush = await GmsServices.instance.messaging.wasAppOpenedByPush();

// Получение последнего открытого пуша в пределах 24 часов
final lastPush = await GmsServices.instance.messaging.getLastOpenedPushWithin24Hours();
if (lastPush != null) {
  print('Последний пуш: ${lastPush.messageId}');
}

// Отметить последний пуш как просмотренный
await GmsServices.instance.messaging.markLastOpenedPushAsViewed();
```

### Работа с Storage

Плагин использует Hive для хранения данных. Вы можете создать собственные экземпляры Storage для хранения любых данных:

```dart
import 'package:gms_services/src/storage/storage.dart';

// Создание storage для ваших данных
final storage = Storage('my_data');

// Инициализация
await storage.init();

// Сохранение данных
await storage.save('key1', {'title': 'Заголовок', 'value': 123});

// Получение данных
final data = storage.get('key1');
print(data); // {'title': 'Заголовок', 'value': 123}

// Получение всех данных
final allData = storage.getAll();

// Удаление данных
await storage.delete('key1');

// Очистка всех данных
await storage.clear();

// Количество записей
final count = storage.count;
```

## Доступные адаптеры

Плагин предоставляет следующие адаптеры:

- **Analytics** - работа с Firebase Analytics
- **RemoteConfig** - работа с Firebase Remote Config
- **Messaging** - работа с Firebase Cloud Messaging (push-уведомления)
- **Storage** - универсальное хранилище данных на основе Hive

## Лицензия

См. файл LICENSE.
