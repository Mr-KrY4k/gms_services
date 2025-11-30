#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Скрипт для автоматической настройки Android проекта для использования
/// плагина gms_services.
///
/// Этот скрипт автоматически добавляет необходимые плагины Google Services
/// в файлы settings.gradle.kts и app/build.gradle.kts.
///
/// Использование:
///   dart run gms_services:setup

const String googleServicesPlugin =
    'id("com.google.gms.google-services") version "4.4.2" apply false';
const String crashlyticsPlugin =
    'id("com.google.firebase.crashlytics") version "3.0.2" apply false';
const String googleServicesApply = 'id("com.google.gms.google-services")';
const String crashlyticsApply = 'id("com.google.firebase.crashlytics")';
const String playServicesLocation =
    'implementation("com.google.android.gms:play-services-location:21.3.0")';
const String installReferrer =
    'implementation("com.android.installreferrer:installreferrer:2.2")';

void main(List<String> args) {
  print('🔧 Настройка Android проекта для плагина gms_services...\n');

  // Определяем корневую директорию проекта
  final projectRoot = _findProjectRoot();
  if (projectRoot == null) {
    print('❌ Ошибка: Не найдена корневая директория Flutter проекта.');
    print('   Убедитесь, что вы запускаете скрипт из корня проекта.');
    exit(1);
  }

  final androidDir = Directory('${projectRoot.path}/android');
  if (!androidDir.existsSync()) {
    print('❌ Ошибка: Директория android не найдена.');
    exit(1);
  }

  bool changesMade = false;

  // Настройка settings.gradle.kts
  final settingsFile = File('${androidDir.path}/settings.gradle.kts');
  if (settingsFile.existsSync()) {
    print('📝 Обновление settings.gradle.kts...');
    if (_updateSettingsGradle(settingsFile)) {
      changesMade = true;
      print('✅ settings.gradle.kts обновлен успешно.');
    } else {
      print('ℹ️  settings.gradle.kts уже содержит необходимые настройки.');
    }
  } else {
    print('⚠️  Файл settings.gradle.kts не найден. Пропуск...');
  }

  // Настройка app/build.gradle.kts
  final appBuildFile = File('${androidDir.path}/app/build.gradle.kts');
  if (appBuildFile.existsSync()) {
    print('📝 Обновление app/build.gradle.kts...');
    bool pluginsUpdated = false;
    bool dependenciesUpdated = false;

    if (_updateAppBuildGradle(appBuildFile)) {
      pluginsUpdated = true;
      changesMade = true;
    }

    if (_addDependencies(appBuildFile)) {
      dependenciesUpdated = true;
      changesMade = true;
    }

    if (pluginsUpdated || dependenciesUpdated) {
      print('✅ app/build.gradle.kts обновлен успешно.');
    } else {
      print('ℹ️  app/build.gradle.kts уже содержит необходимые настройки.');
    }
  } else {
    print('⚠️  Файл app/build.gradle.kts не найден. Пропуск...');
  }

  if (changesMade) {
    print('\n✅ Настройка завершена! Не забудьте:');
    print('   1. Добавить файл google-services.json в android/app/');
    print('   2. Выполнить flutter pub get');
    print('   3. Пересобрать проект');
  } else {
    print('\n✅ Проект уже настроен правильно!');
  }
}

Directory? _findProjectRoot() {
  Directory current = Directory.current;
  while (current.path != current.parent.path) {
    final pubspecFile = File('${current.path}/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

bool _updateSettingsGradle(File file) {
  final content = file.readAsStringSync();

  // Проверяем, есть ли уже плагины
  if (content.contains('com.google.gms.google-services')) {
    return false; // Уже настроено
  }

  // Ищем блок plugins (многострочный)
  final pluginsBlockRegex = RegExp(
    r'plugins\s*\{[^}]*\}',
    multiLine: true,
    dotAll: true,
  );

  final match = pluginsBlockRegex.firstMatch(content);
  if (match != null) {
    final pluginsBlock = match.group(0)!;

    // Проверяем, есть ли уже нужные плагины в блоке
    if (pluginsBlock.contains('com.google.gms.google-services')) {
      return false;
    }

    // Добавляем плагины перед закрывающей скобкой блока
    final updatedPluginsBlock = pluginsBlock.replaceFirst(
      '}',
      '    // Плагины для gms_services:\n    $googleServicesPlugin\n    $crashlyticsPlugin\n}',
    );

    final newContent = content.replaceFirst(pluginsBlock, updatedPluginsBlock);
    file.writeAsStringSync(newContent);
    return true;
  } else {
    // Если блока plugins нет, добавляем после pluginManagement
    final pluginManagementEnd = content.indexOf('include(');
    if (pluginManagementEnd == -1) {
      // Если нет include, добавляем в конец
      final newContent =
          '$content\n\nplugins {\n    // Плагины для gms_services:\n    $googleServicesPlugin\n    $crashlyticsPlugin\n}\n';
      file.writeAsStringSync(newContent);
      return true;
    } else {
      // Вставляем перед include
      final before = content.substring(0, pluginManagementEnd);
      final after = content.substring(pluginManagementEnd);
      final newContent =
          '$before\nplugins {\n    // Плагины для gms_services:\n    $googleServicesPlugin\n    $crashlyticsPlugin\n}\n\n$after';
      file.writeAsStringSync(newContent);
      return true;
    }
  }
}

bool _updateAppBuildGradle(File file) {
  final content = file.readAsStringSync();

  // Проверяем, есть ли уже применение плагинов
  if (content.contains(googleServicesApply)) {
    return false; // Уже настроено
  }

  // Ищем блок plugins (многострочный)
  final pluginsBlockRegex = RegExp(
    r'plugins\s*\{[^}]*\}',
    multiLine: true,
    dotAll: true,
  );

  final match = pluginsBlockRegex.firstMatch(content);
  if (match != null) {
    final pluginsBlock = match.group(0)!;

    // Добавляем применение плагинов перед закрывающей скобкой
    final updatedPluginsBlock = pluginsBlock.replaceFirst(
      '}',
      '    // Плагины для gms_services:\n    $googleServicesApply\n    $crashlyticsApply\n}',
    );

    final newContent = content.replaceFirst(pluginsBlock, updatedPluginsBlock);
    file.writeAsStringSync(newContent);
    return true;
  } else {
    // Если блока plugins нет, добавляем в начало файла
    final newContent =
        'plugins {\n    // Плагины для gms_services:\n    $googleServicesApply\n    $crashlyticsApply\n}\n\n$content';
    file.writeAsStringSync(newContent);
    return true;
  }
}

bool _addDependencies(File file) {
  final content = file.readAsStringSync();

  // Проверяем, есть ли уже зависимости
  if (content.contains('play-services-location:21.3.0') &&
      content.contains('installreferrer:2.2')) {
    return false; // Уже добавлено
  }

  // Ищем блок dependencies
  final dependenciesBlockRegex = RegExp(
    r'dependencies\s*\{[^}]*\}',
    multiLine: true,
    dotAll: true,
  );

  final match = dependenciesBlockRegex.firstMatch(content);
  if (match != null) {
    // Блок dependencies существует
    final dependenciesBlock = match.group(0)!;

    // Проверяем, есть ли уже нужные зависимости в блоке
    if (dependenciesBlock.contains('play-services-location:21.3.0') &&
        dependenciesBlock.contains('installreferrer:2.2')) {
      return false;
    }

    // Добавляем зависимости перед закрывающей скобкой блока
    String dependenciesToAdd = '';
    if (!dependenciesBlock.contains('play-services-location:21.3.0')) {
      dependenciesToAdd +=
          '    // Зависимости для gms_services:\n    $playServicesLocation\n';
    }
    if (!dependenciesBlock.contains('installreferrer:2.2')) {
      if (!dependenciesToAdd.contains('// Зависимости для gms_services:')) {
        dependenciesToAdd += '    // Зависимости для gms_services:\n';
      }
      dependenciesToAdd += '    $installReferrer\n';
    }

    if (dependenciesToAdd.isNotEmpty) {
      final updatedDependenciesBlock = dependenciesBlock.replaceFirst(
        '}',
        dependenciesToAdd + '}',
      );

      final newContent = content.replaceFirst(
        dependenciesBlock,
        updatedDependenciesBlock,
      );
      file.writeAsStringSync(newContent);
      return true;
    }
  } else {
    // Блока dependencies нет, создаем его после блока flutter
    final flutterBlockRegex = RegExp(
      r'flutter\s*\{[^}]*\}',
      multiLine: true,
      dotAll: true,
    );

    final flutterMatch = flutterBlockRegex.firstMatch(content);
    if (flutterMatch != null) {
      // Добавляем после блока flutter
      final flutterBlock = flutterMatch.group(0)!;
      final flutterBlockEnd =
          content.indexOf(flutterBlock) + flutterBlock.length;
      final before = content.substring(0, flutterBlockEnd);
      final after = content.substring(flutterBlockEnd);

      final newContent =
          '$before\n\ndependencies {\n    // Зависимости для gms_services:\n    $playServicesLocation\n    $installReferrer\n}\n$after';
      file.writeAsStringSync(newContent);
      return true;
    } else {
      // Если блока flutter нет, добавляем в конец файла
      final newContent =
          '$content\n\ndependencies {\n    // Зависимости для gms_services:\n    $playServicesLocation\n    $installReferrer\n}\n';
      file.writeAsStringSync(newContent);
      return true;
    }
  }

  return false;
}
