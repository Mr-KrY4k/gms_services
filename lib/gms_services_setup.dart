/// Публичный API для программной настройки и очистки Android проекта.
///
/// Этот модуль позволяет другим плагинам программно вызывать функции
/// setup и cleanup для автоматической настройки Android проекта.
library gms_services_setup;

import 'dart:io';
import 'src/setup_helper.dart' as helper;

/// Результат выполнения операции настройки/очистки.
///
/// Экспортируется из внутреннего модуля для публичного использования.
typedef SetupResult = helper.SetupResult;

/// Настраивает Android проект для использования плагина gms_services.
///
/// Эта функция автоматически добавляет необходимые плагины Google Services,
/// зависимости и настройки в файлы проекта.
///
/// [projectRoot] - опциональный путь к корневой директории Flutter проекта.
/// Если не указан, будет использоваться автоматический поиск.
///
/// Возвращает [SetupResult] с информацией о выполненных изменениях.
///
/// Пример использования:
/// ```dart
/// import 'package:gms_services/gms_services_setup.dart';
///
/// final result = await setupGmsServices();
/// if (result.changesMade) {
///   print('Настройка завершена');
///   for (final message in result.messages) {
///     print(message);
///   }
/// }
/// ```
Future<SetupResult> setupGmsServices({String? projectRoot}) async {
  final messages = <String>[];
  bool changesMade = false;

  // Определяем корневую директорию проекта
  final root = projectRoot != null
      ? Directory(projectRoot)
      : helper.findProjectRoot();
  if (root == null) {
    return SetupResult(
      changesMade: false,
      messages: [
        '❌ Ошибка: Не найдена корневая директория Flutter проекта.',
        '   Убедитесь, что вы запускаете скрипт из корня проекта.',
      ],
    );
  }

  final androidDir = Directory('${root.path}/android');
  if (!androidDir.existsSync()) {
    return SetupResult(
      changesMade: false,
      messages: ['❌ Ошибка: Директория android не найдена.'],
    );
  }

  // Настройка settings.gradle.kts
  final settingsFile = File('${androidDir.path}/settings.gradle.kts');
  if (settingsFile.existsSync()) {
    messages.add('📝 Обновление settings.gradle.kts...');
    if (helper.updateSettingsGradle(settingsFile)) {
      changesMade = true;
      messages.add('✅ settings.gradle.kts обновлен успешно.');
    } else {
      messages.add(
        'ℹ️  settings.gradle.kts уже содержит необходимые настройки.',
      );
    }
  } else {
    messages.add('⚠️  Файл settings.gradle.kts не найден. Пропуск...');
  }

  // Настройка app/build.gradle.kts
  final appBuildFile = File('${androidDir.path}/app/build.gradle.kts');
  if (appBuildFile.existsSync()) {
    messages.add('📝 Обновление app/build.gradle.kts...');
    bool pluginsUpdated = false;
    bool dependenciesUpdated = false;

    if (helper.updateAppBuildGradle(appBuildFile)) {
      pluginsUpdated = true;
      changesMade = true;
    }

    if (helper.addDependencies(appBuildFile)) {
      dependenciesUpdated = true;
      changesMade = true;
    }

    if (pluginsUpdated || dependenciesUpdated) {
      messages.add('✅ app/build.gradle.kts обновлен успешно.');
    } else {
      messages.add(
        'ℹ️  app/build.gradle.kts уже содержит необходимые настройки.',
      );
    }
  } else {
    messages.add('⚠️  Файл app/build.gradle.kts не найден. Пропуск...');
  }

  // Настройка AndroidManifest.xml
  final manifestFile = File(
    '${androidDir.path}/app/src/main/AndroidManifest.xml',
  );
  if (manifestFile.existsSync()) {
    messages.add('📝 Обновление AndroidManifest.xml...');
    if (helper.updateAndroidManifest(manifestFile)) {
      changesMade = true;
      messages.add('✅ AndroidManifest.xml обновлен успешно.');
    } else {
      messages.add(
        'ℹ️  AndroidManifest.xml уже содержит необходимые настройки.',
      );
    }
  } else {
    messages.add('⚠️  Файл AndroidManifest.xml не найден. Пропуск...');
  }

  // Добавляем финальные сообщения для пользователя
  if (changesMade) {
    messages.add('');
    messages.add('✅ Настройка завершена! Не забудьте:');
    messages.add('   1. Добавить файл google-services.json в android/app/');
    messages.add('   2. Добавить иконку для пуш-уведомлений:');
    messages.add(
      '      android/app/src/main/res/drawable/firebase_icon_push.png',
    );
    messages.add('   3. Выполнить flutter pub get');
    messages.add('   4. Пересобрать проект');
  } else {
    messages.add('');
    messages.add('✅ Проект уже настроен правильно!');
  }

  return SetupResult(changesMade: changesMade, messages: messages);
}

/// Удаляет настройки Android проекта для плагина gms_services.
///
/// Эта функция автоматически удаляет плагины Google Services,
/// зависимости и настройки из файлов проекта.
///
/// [projectRoot] - опциональный путь к корневой директории Flutter проекта.
/// Если не указан, будет использоваться автоматический поиск.
///
/// Возвращает [SetupResult] с информацией о выполненных изменениях.
///
/// Пример использования:
/// ```dart
/// import 'package:gms_services/gms_services_setup.dart';
///
/// final result = await cleanupGmsServices();
/// if (result.changesMade) {
///   print('Очистка завершена');
///   for (final message in result.messages) {
///     print(message);
///   }
/// }
/// ```
Future<SetupResult> cleanupGmsServices({String? projectRoot}) async {
  final messages = <String>[];
  bool changesMade = false;

  // Определяем корневую директорию проекта
  final root = projectRoot != null
      ? Directory(projectRoot)
      : helper.findProjectRoot();
  if (root == null) {
    return SetupResult(
      changesMade: false,
      messages: [
        '❌ Ошибка: Не найдена корневая директория Flutter проекта.',
        '   Убедитесь, что вы запускаете скрипт из корня проекта.',
      ],
    );
  }

  final androidDir = Directory('${root.path}/android');
  if (!androidDir.existsSync()) {
    return SetupResult(
      changesMade: false,
      messages: ['❌ Ошибка: Директория android не найдена.'],
    );
  }

  // Удаление из settings.gradle.kts
  final settingsFile = File('${androidDir.path}/settings.gradle.kts');
  if (settingsFile.existsSync()) {
    messages.add('📝 Обновление settings.gradle.kts...');
    if (helper.removeFromSettingsGradle(settingsFile)) {
      changesMade = true;
      messages.add('✅ Плагины удалены из settings.gradle.kts.');
    } else {
      messages.add('ℹ️  Плагины не найдены в settings.gradle.kts.');
    }
  } else {
    messages.add('⚠️  Файл settings.gradle.kts не найден. Пропуск...');
  }

  // Удаление из app/build.gradle.kts
  final appBuildFile = File('${androidDir.path}/app/build.gradle.kts');
  if (appBuildFile.existsSync()) {
    messages.add('📝 Обновление app/build.gradle.kts...');
    bool pluginsRemoved = false;
    bool dependenciesRemoved = false;

    if (helper.removeFromAppBuildGradle(appBuildFile)) {
      pluginsRemoved = true;
      changesMade = true;
    }

    if (helper.removeDependencies(appBuildFile)) {
      dependenciesRemoved = true;
      changesMade = true;
    }

    if (pluginsRemoved || dependenciesRemoved) {
      messages.add('✅ Настройки удалены из app/build.gradle.kts.');
    } else {
      messages.add('ℹ️  Настройки не найдены в app/build.gradle.kts.');
    }
  } else {
    messages.add('⚠️  Файл app/build.gradle.kts не найден. Пропуск...');
  }

  // Удаление из AndroidManifest.xml
  final manifestFile = File(
    '${androidDir.path}/app/src/main/AndroidManifest.xml',
  );
  if (manifestFile.existsSync()) {
    messages.add('📝 Обновление AndroidManifest.xml...');
    if (helper.removeFromAndroidManifest(manifestFile)) {
      changesMade = true;
      messages.add('✅ Настройки удалены из AndroidManifest.xml.');
    } else {
      messages.add('ℹ️  Настройки не найдены в AndroidManifest.xml.');
    }
  } else {
    messages.add('⚠️  Файл AndroidManifest.xml не найден. Пропуск...');
  }

  // Добавляем финальное сообщение
  messages.add('');
  if (changesMade) {
    messages.add('✅ Удаление настроек завершено!');
  } else {
    messages.add('✅ Настройки уже удалены или не найдены!');
  }

  return SetupResult(changesMade: changesMade, messages: messages);
}
