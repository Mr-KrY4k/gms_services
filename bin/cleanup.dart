#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Скрипт для удаления настроек Android проекта для плагина gms_services.
///
/// Этот скрипт автоматически удаляет плагины Google Services
/// из файлов settings.gradle.kts и app/build.gradle.kts.
///
/// Использование:
///   dart run gms_services:cleanup

void main(List<String> args) {
  print('🗑️  Удаление настроек Android проекта для плагина gms_services...\n');

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

  // Удаление из settings.gradle.kts
  final settingsFile = File('${androidDir.path}/settings.gradle.kts');
  if (settingsFile.existsSync()) {
    print('📝 Обновление settings.gradle.kts...');
    if (_removeFromSettingsGradle(settingsFile)) {
      changesMade = true;
      print('✅ Плагины удалены из settings.gradle.kts.');
    } else {
      print('ℹ️  Плагины не найдены в settings.gradle.kts.');
    }
  } else {
    print('⚠️  Файл settings.gradle.kts не найден. Пропуск...');
  }

  // Удаление из app/build.gradle.kts
  final appBuildFile = File('${androidDir.path}/app/build.gradle.kts');
  if (appBuildFile.existsSync()) {
    print('📝 Обновление app/build.gradle.kts...');
    if (_removeFromAppBuildGradle(appBuildFile)) {
      changesMade = true;
      print('✅ Плагины удалены из app/build.gradle.kts.');
    } else {
      print('ℹ️  Плагины не найдены в app/build.gradle.kts.');
    }
  } else {
    print('⚠️  Файл app/build.gradle.kts не найден. Пропуск...');
  }

  if (changesMade) {
    print('\n✅ Удаление настроек завершено!');
  } else {
    print('\n✅ Настройки уже удалены или не найдены!');
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

bool _removeFromSettingsGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли плагины
  final hasPlugins = lines.any((line) => 
    line.contains('com.google.gms.google-services') ||
    line.contains('com.google.firebase.crashlytics')
  );

  if (!hasPlugins) {
    return false; // Нечего удалять
  }

  final newLines = <String>[];
  bool foundComment = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Пропускаем комментарий
    if (trimmed.contains('// Плагины для gms_services:') ||
        trimmed.contains('//Плагины для gms_services:')) {
      foundComment = true;
      continue;
    }

    // Пропускаем строки с плагинами
    if ((trimmed.contains('com.google.gms.google-services') ||
         trimmed.contains('com.google.firebase.crashlytics')) &&
        (trimmed.contains('apply false') || trimmed.contains('version'))) {
      continue;
    }

    newLines.add(line);
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (newLines.length != lines.length || foundComment) {
    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }

  return false;
}

bool _removeFromAppBuildGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли применение плагинов
  final hasPlugins = lines.any((line) => 
    line.contains('com.google.gms.google-services') ||
    line.contains('com.google.firebase.crashlytics')
  );

  if (!hasPlugins) {
    return false; // Нечего удалять
  }

  final newLines = <String>[];
  bool foundComment = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Пропускаем комментарий
    if (trimmed.contains('// Плагины для gms_services:') ||
        trimmed.contains('//Плагины для gms_services:')) {
      foundComment = true;
      continue;
    }

    // Пропускаем строки с применением плагинов (без version и apply false)
    if ((trimmed.contains('com.google.gms.google-services') ||
         trimmed.contains('com.google.firebase.crashlytics')) &&
        !trimmed.contains('version') &&
        !trimmed.contains('apply false')) {
      continue;
    }

    newLines.add(line);
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (newLines.length != lines.length || foundComment) {
    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }

  return false;
}

