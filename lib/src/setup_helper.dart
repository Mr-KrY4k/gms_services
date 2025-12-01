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

/// Находит границы блока в файле (например, plugins { ... })
/// Возвращает (startIndex, endIndex) или null, если блок не найден
(int, int)? _findBlockBounds(
  List<String> lines,
  String blockName,
  int startFrom,
) {
  int? blockStart;
  int blockDepth = 0;
  bool inBlock = false;

  for (int i = startFrom; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Находим начало блока (например, "plugins {" или "plugins{")
    if (!inBlock && trimmed.startsWith(blockName) && trimmed.contains('{')) {
      blockStart = i;
      inBlock = true;
      blockDepth = 1;
      // Проверяем, не закрылся ли блок в той же строке
      final openBraces = trimmed.split('{').length - 1;
      final closeBraces = trimmed.split('}').length - 1;
      blockDepth +=
          openBraces -
          closeBraces -
          1; // -1 потому что уже посчитали начальную {
      if (blockDepth == 0) {
        return (blockStart!, i);
      }
      continue;
    }

    if (inBlock) {
      // Считаем вложенные скобки в строке
      final openBraces = line.split('{').length - 1;
      final closeBraces = line.split('}').length - 1;
      blockDepth += openBraces - closeBraces;

      // Если блок закрылся
      if (blockDepth == 0) {
        return (blockStart!, i);
      }
    }
  }

  return null;
}

/// Обновляет settings.gradle.kts, добавляя плагины Google Services
bool updateSettingsGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли уже плагины
  final hasPlugins = lines.any(
    (line) =>
        line.contains('com.google.gms.google-services') ||
        line.contains('com.google.firebase.crashlytics'),
  );

  if (hasPlugins) {
    return false; // Уже настроено
  }

  // Ищем блок plugins
  final blockBounds = _findBlockBounds(lines, 'plugins', 0);
  if (blockBounds != null) {
    final (blockStart, blockEnd) = blockBounds;

    // Добавляем плагины перед закрывающей скобкой
    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (i == blockEnd) {
        // Вставляем перед закрывающей скобкой
        newLines.add('    // Плагины для gms_services:');
        newLines.add('    $googleServicesPlugin');
        newLines.add('    $crashlyticsPlugin');
      }
      newLines.add(lines[i]);
    }

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  } else {
    // Если блока plugins нет, создаем его
    // Ищем место для вставки (перед include или в конец)
    int insertIndex = lines.length;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('include(')) {
        insertIndex = i;
        break;
      }
    }

    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (i == insertIndex) {
        newLines.add('');
        newLines.add('plugins {');
        newLines.add('    // Плагины для gms_services:');
        newLines.add('    $googleServicesPlugin');
        newLines.add('    $crashlyticsPlugin');
        newLines.add('}');
        if (insertIndex < lines.length) {
          newLines.add('');
        }
      }
      newLines.add(lines[i]);
    }

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }
}

/// Обновляет app/build.gradle.kts, добавляя применение плагинов
bool updateAppBuildGradle(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли уже применение плагинов
  final hasPlugins = lines.any(
    (line) =>
        (line.contains('com.google.gms.google-services') ||
            line.contains('com.google.firebase.crashlytics')) &&
        !line.contains('version') &&
        !line.contains('apply false'),
  );

  if (hasPlugins) {
    return false; // Уже настроено
  }

  // Ищем блок plugins
  final blockBounds = _findBlockBounds(lines, 'plugins', 0);
  if (blockBounds != null) {
    final (blockStart, blockEnd) = blockBounds;

    // Добавляем применение плагинов перед закрывающей скобкой
    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (i == blockEnd) {
        // Вставляем перед закрывающей скобкой
        newLines.add('    // Плагины для gms_services:');
        newLines.add('    $googleServicesApply');
        newLines.add('    $crashlyticsApply');
      }
      newLines.add(lines[i]);
    }

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  } else {
    // Если блока plugins нет, добавляем в начало файла
    final newLines = <String>[];
    newLines.add('plugins {');
    newLines.add('    // Плагины для gms_services:');
    newLines.add('    $googleServicesApply');
    newLines.add('    $crashlyticsApply');
    newLines.add('}');
    newLines.add('');
    newLines.addAll(lines);

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }
}

/// Добавляет зависимости в app/build.gradle.kts
bool addDependencies(File file) {
  final lines = file.readAsLinesSync();

  // Проверяем, есть ли уже зависимости
  final hasDependencies = lines.any(
    (line) =>
        line.contains('play-services-location:21.3.0') ||
        line.contains('installreferrer:2.2'),
  );

  if (hasDependencies) {
    return false; // Уже добавлено
  }

  // Ищем блок dependencies
  final blockBounds = _findBlockBounds(lines, 'dependencies', 0);
  if (blockBounds != null) {
    final (blockStart, blockEnd) = blockBounds;

    // Добавляем зависимости перед закрывающей скобкой
    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      if (i == blockEnd) {
        // Вставляем перед закрывающей скобкой
        newLines.add('    // Зависимости для gms_services:');
        newLines.add('    $playServicesLocation');
        newLines.add('    $installReferrer');
      }
      newLines.add(lines[i]);
    }

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  } else {
    // Блока dependencies нет, создаем его после блока flutter
    int flutterBlockEnd = -1;
    final flutterBlockBounds = _findBlockBounds(lines, 'flutter', 0);
    if (flutterBlockBounds != null) {
      flutterBlockEnd = flutterBlockBounds.$2;
    }

    final newLines = <String>[];
    for (int i = 0; i < lines.length; i++) {
      newLines.add(lines[i]);
      if (i == flutterBlockEnd ||
          (flutterBlockEnd == -1 && i == lines.length - 1)) {
        newLines.add('');
        newLines.add('dependencies {');
        newLines.add('    // Зависимости для gms_services:');
        newLines.add('    $playServicesLocation');
        newLines.add('    $installReferrer');
        newLines.add('}');
      }
    }

    file.writeAsStringSync(newLines.join('\n') + '\n');
    return true;
  }
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

  // Ищем блок plugins
  final blockBounds = _findBlockBounds(lines, 'plugins', 0);

  final newLines = <String>[];
  bool foundChanges = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Пропускаем комментарий
    if (trimmed.contains('// Плагины для gms_services:') ||
        trimmed.contains('//Плагины для gms_services:')) {
      foundChanges = true;
      continue;
    }

    // Пропускаем строки с плагинами
    if ((trimmed.contains('com.google.gms.google-services') ||
            trimmed.contains('com.google.firebase.crashlytics')) &&
        (trimmed.contains('apply false') || trimmed.contains('version'))) {
      foundChanges = true;
      continue;
    }

    newLines.add(line);
  }

  // Проверяем, нужно ли удалить пустой блок plugins
  if (blockBounds != null && foundChanges) {
    final (blockStart, blockEnd) = blockBounds;

    // Проверяем, остались ли в блоке только наши строки
    bool hasOtherContent = false;
    for (int i = blockStart + 1; i < blockEnd; i++) {
      final trimmed = newLines[i].trim();
      if (trimmed.isNotEmpty &&
          !trimmed.contains('// Плагины для gms_services:') &&
          !trimmed.contains('com.google.gms.google-services') &&
          !trimmed.contains('com.google.firebase.crashlytics')) {
        hasOtherContent = true;
        break;
      }
    }

    // Если блока plugins не осталось содержимого (только наши строки), удаляем весь блок
    if (!hasOtherContent &&
        blockStart < newLines.length &&
        blockEnd < newLines.length) {
      final finalLines = <String>[];
      for (int i = 0; i < newLines.length; i++) {
        if (i < blockStart || i > blockEnd) {
          finalLines.add(newLines[i]);
        }
      }

      // Удаляем лишние пустые строки
      while (finalLines.isNotEmpty && finalLines.last.trim().isEmpty) {
        finalLines.removeLast();
      }

      newLines.clear();
      newLines.addAll(finalLines);
    }
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (foundChanges) {
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

  // Ищем блок plugins
  final blockBounds = _findBlockBounds(lines, 'plugins', 0);

  final newLines = <String>[];
  bool foundChanges = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Пропускаем комментарий
    if (trimmed.contains('// Плагины для gms_services:') ||
        trimmed.contains('//Плагины для gms_services:')) {
      foundChanges = true;
      continue;
    }

    // Пропускаем строки с применением плагинов (без version и apply false)
    if ((trimmed.contains('com.google.gms.google-services') ||
            trimmed.contains('com.google.firebase.crashlytics')) &&
        !trimmed.contains('version') &&
        !trimmed.contains('apply false')) {
      foundChanges = true;
      continue;
    }

    newLines.add(line);
  }

  // Проверяем, нужно ли удалить пустой блок plugins
  if (blockBounds != null && foundChanges) {
    final (blockStart, blockEnd) = blockBounds;

    // Проверяем, остались ли в блоке только наши строки
    bool hasOtherContent = false;
    for (int i = blockStart + 1; i < blockEnd && i < newLines.length; i++) {
      final trimmed = newLines[i].trim();
      if (trimmed.isNotEmpty &&
          !trimmed.contains('// Плагины для gms_services:') &&
          !trimmed.contains('com.google.gms.google-services') &&
          !trimmed.contains('com.google.firebase.crashlytics')) {
        hasOtherContent = true;
        break;
      }
    }

    // Если блока plugins не осталось содержимого, удаляем весь блок
    if (!hasOtherContent &&
        blockStart < newLines.length &&
        blockEnd < newLines.length) {
      final finalLines = <String>[];
      for (int i = 0; i < newLines.length; i++) {
        if (i < blockStart || i > blockEnd) {
          finalLines.add(newLines[i]);
        }
      }

      // Удаляем лишние пустые строки
      while (finalLines.isNotEmpty && finalLines.last.trim().isEmpty) {
        finalLines.removeLast();
      }

      newLines.clear();
      newLines.addAll(finalLines);
    }
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (foundChanges) {
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

  // Ищем блок dependencies
  final blockBounds = _findBlockBounds(lines, 'dependencies', 0);
  if (blockBounds == null) {
    return false; // Блок dependencies не найден
  }

  final (blockStart, blockEnd) = blockBounds;
  final newLines = <String>[];
  bool foundChanges = false;

  // Обрабатываем строки - удаляем только наши зависимости
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();

    // Если это внутри блока dependencies
    if (i > blockStart && i < blockEnd) {
      // Пропускаем комментарий
      if (trimmed.contains('// Зависимости для gms_services:') ||
          trimmed.contains('//Зависимости для gms_services:')) {
        foundChanges = true;
        continue;
      }

      // Пропускаем зависимости
      if (trimmed.contains('play-services-location:21.3.0') ||
          trimmed.contains('installreferrer:2.2')) {
        foundChanges = true;
        continue;
      }
    }

    // Оставляем все остальные строки
    newLines.add(line);
  }

  // Проверяем, остался ли блок dependencies пустым (только наши зависимости)
  if (foundChanges) {
    // Находим блок dependencies в новом массиве после удаления
    final newBlockBounds = _findBlockBounds(newLines, 'dependencies', 0);
    if (newBlockBounds != null) {
      final (newBlockStart, newBlockEnd) = newBlockBounds;

      // Проверяем, пуст ли блок (содержит только пустые строки и комментарии)
      bool hasContent = false;
      for (int i = newBlockStart + 1; i < newBlockEnd; i++) {
        final trimmed = newLines[i].trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('//')) {
          hasContent = true;
          break;
        }
      }

      // Если блок пуст, удаляем его полностью
      if (!hasContent) {
        final finalLines = <String>[];
        for (int i = 0; i < newLines.length; i++) {
          if (i < newBlockStart || i > newBlockEnd) {
            finalLines.add(newLines[i]);
          }
        }

        // Удаляем лишние пустые строки
        while (finalLines.isNotEmpty && finalLines.last.trim().isEmpty) {
          finalLines.removeLast();
        }

        newLines.clear();
        newLines.addAll(finalLines);
      }
    }
  }

  // Удаляем лишние пустые строки в конце
  while (newLines.isNotEmpty && newLines.last.trim().isEmpty) {
    newLines.removeLast();
  }

  if (foundChanges) {
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
