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
    bool pluginsRemoved = false;
    bool dependenciesRemoved = false;
    
    if (_removeFromAppBuildGradle(appBuildFile)) {
      pluginsRemoved = true;
      changesMade = true;
    }
    
    if (_removeDependencies(appBuildFile)) {
      dependenciesRemoved = true;
      changesMade = true;
    }
    
    if (pluginsRemoved || dependenciesRemoved) {
      print('✅ Настройки удалены из app/build.gradle.kts.');
    } else {
      print('ℹ️  Настройки не найдены в app/build.gradle.kts.');
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

bool _removeDependencies(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли зависимости
  final hasDependencies = lines.any((line) => 
    line.contains('play-services-location:21.3.0') ||
    line.contains('installreferrer:2.2')
  );

  if (!hasDependencies) {
    return false; // Нечего удалять
  }

  final newLines = <String>[];
  bool inDependenciesBlock = false;
  int dependenciesBlockStart = -1;
  int dependenciesBlockEnd = -1;
  bool foundDependencies = false;

  // Находим блок dependencies
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    if (trimmed.startsWith('dependencies') && trimmed.contains('{')) {
      inDependenciesBlock = true;
      dependenciesBlockStart = i;
      continue;
    }

    if (inDependenciesBlock && trimmed == '}') {
      dependenciesBlockEnd = i;
      break;
    }
  }

  if (dependenciesBlockStart == -1) {
    return false; // Блок dependencies не найден
  }

  // Обрабатываем строки - удаляем только наши зависимости
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Если это внутри блока dependencies
    if (i > dependenciesBlockStart && i < dependenciesBlockEnd) {
      // Пропускаем комментарий
      if (trimmed.contains('// Зависимости для gms_services:') ||
          trimmed.contains('//Зависимости для gms_services:')) {
        foundDependencies = true;
        continue;
      }

      // Пропускаем зависимости
      if (trimmed.contains('play-services-location:21.3.0') ||
          trimmed.contains('installreferrer:2.2')) {
        foundDependencies = true;
        continue;
      }
    }

    // Оставляем все остальные строки
    newLines.add(line);
  }

  // Проверяем, остался ли блок dependencies пустым (только наши зависимости)
  if (dependenciesBlockStart != -1 && dependenciesBlockEnd != -1 && foundDependencies) {
    bool isEmpty = true;
    for (int i = dependenciesBlockStart + 1; i < dependenciesBlockEnd; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && 
          !trimmed.contains('// Зависимости для gms_services:') &&
          !trimmed.contains('play-services-location:21.3.0') &&
          !trimmed.contains('installreferrer:2.2')) {
        isEmpty = false;
        break;
      }
    }

    // Если блок пуст (только наши зависимости), удаляем его полностью
    if (isEmpty) {
      newLines.clear();
      for (int i = 0; i < lines.length; i++) {
        if (i < dependenciesBlockStart || i > dependenciesBlockEnd) {
          newLines.add(lines[i]);
        }
      }
    }
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (newLines.length != lines.length || foundDependencies) {
    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }

  return false;
}

