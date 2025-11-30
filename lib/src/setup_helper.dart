/// Внутренний модуль с общей логикой для настройки и очистки Android проекта.
library gms_services_setup_helper;

import 'dart:io';

/// Результат выполнения операции настройки/очистки.
class SetupResult {
  /// Были ли внесены изменения в файлы.
  final bool changesMade;

  /// Сообщения о выполненных операциях.
  final List<String> messages;

  SetupResult({required this.changesMade, required this.messages});
}

/// Константы для плагинов и зависимостей
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
const String firebaseNotificationIcon =
    '<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/firebase_icon_push"/>';

/// Находит корневую директорию Flutter проекта
Directory? findProjectRoot([String? startPath]) {
  Directory current = startPath != null
      ? Directory(startPath)
      : Directory.current;
  while (current.path != current.parent.path) {
    final pubspecFile = File('${current.path}/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

/// Обновляет settings.gradle.kts, добавляя плагины Google Services
bool updateSettingsGradle(File file) {
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

/// Обновляет app/build.gradle.kts, добавляя применение плагинов
bool updateAppBuildGradle(File file) {
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

/// Добавляет зависимости в app/build.gradle.kts
bool addDependencies(File file) {
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

/// Обновляет AndroidManifest.xml, добавляя настройку иконки уведомлений
bool updateAndroidManifest(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли уже meta-data для Firebase notification icon
  final hasMetaData = lines.any(
    (line) => line.contains(
      'com.google.firebase.messaging.default_notification_icon',
    ),
  );

  if (hasMetaData) {
    return false; // Уже добавлено
  }

  // Ищем закрывающий тег application
  int applicationCloseIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].trim() == '</application>') {
      applicationCloseIndex = i;
      break;
    }
  }

  if (applicationCloseIndex == -1) {
    return false; // Закрывающий тег application не найден
  }

  // Определяем отступ для вставки (обычно 8 пробелов для элементов внутри application)
  final indent = '        ';

  // Вставляем meta-data перед закрывающим тегом application
  final newLines = <String>[];
  for (int i = 0; i < lines.length; i++) {
    if (i == applicationCloseIndex) {
      // Вставляем перед закрывающим тегом
      newLines.add('$indent$firebaseNotificationIcon');
      newLines.add(lines[i]);
    } else {
      newLines.add(lines[i]);
    }
  }

  file.writeAsStringSync(newLines.join('\n') + '\n');
  return true;
}

/// Удаляет настройки из settings.gradle.kts
bool removeFromSettingsGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли плагины
  final hasPlugins = lines.any(
    (line) =>
        line.contains('com.google.gms.google-services') ||
        line.contains('com.google.firebase.crashlytics'),
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

/// Удаляет настройки из app/build.gradle.kts
bool removeFromAppBuildGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли применение плагинов
  final hasPlugins = lines.any(
    (line) =>
        line.contains('com.google.gms.google-services') ||
        line.contains('com.google.firebase.crashlytics'),
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

/// Удаляет зависимости из app/build.gradle.kts
bool removeDependencies(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли зависимости
  final hasDependencies = lines.any(
    (line) =>
        line.contains('play-services-location:21.3.0') ||
        line.contains('installreferrer:2.2'),
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
  if (dependenciesBlockStart != -1 &&
      dependenciesBlockEnd != -1 &&
      foundDependencies) {
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

/// Удаляет настройки из AndroidManifest.xml
bool removeFromAndroidManifest(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли meta-data для Firebase notification icon
  final hasMetaData = lines.any(
    (line) => line.contains(
      'com.google.firebase.messaging.default_notification_icon',
    ),
  );

  if (!hasMetaData) {
    return false; // Нечего удалять
  }

  final newLines = <String>[];
  bool found = false;

  for (final line in lines) {
    // Пропускаем строку с meta-data для Firebase notification icon
    if (line.contains(
      'com.google.firebase.messaging.default_notification_icon',
    )) {
      found = true;
      continue;
    }
    newLines.add(line);
  }

  if (found) {
    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }

  return false;
}
