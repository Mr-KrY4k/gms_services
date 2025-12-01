import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:gms_services/src/logger.dart';

/// Адаптер для работы с Firebase Remote Config.
///
/// Предоставляет упрощенный интерфейс для инициализации и получения
/// конфигурационных данных из Firebase Remote Config.
///
/// Пример использования:
/// ```dart
/// await RemoteConfig.instance.initialize();
/// final value = RemoteConfig.instance.getString('my_key');
/// ```
final class RemoteConfig {
  RemoteConfig._();

  /// Единственный экземпляр класса.
  static final RemoteConfig instance = RemoteConfig._();

  /// Настройки для Remote Config.
  ///
  /// Установлены нулевые таймауты для немедленной загрузки конфигурации.
  final _settings = RemoteConfigSettings(
    fetchTimeout: Duration.zero,
    minimumFetchInterval: Duration.zero,
  );

  /// Экземпляр Firebase Remote Config.
  late final FirebaseRemoteConfig _firebaseRemoteConfig =
      FirebaseRemoteConfig.instance;

  /// Флаг инициализации.
  bool _isInitialized = false;

  /// Флаг выполнения инициализации.
  bool _isPending = false;

  /// Completer для получения данных после инициализации.
  final _dataCompleter = Completer<Map<String, dynamic>>();

  /// Инициализирует Remote Config.
  ///
  /// Настраивает параметры загрузки и получает конфигурацию из Firebase.
  /// Метод безопасен для повторного вызова - повторная инициализация
  /// будет пропущена, если уже выполняется или завершена.
  ///
  /// Выбрасывает исключение, если инициализация не удалась.
  Future<void> initialize() async {
    if (_isInitialized) {
      GmsLogger.debug('RemoteConfig: уже инициализирован');
      return;
    }

    if (_isPending) {
      GmsLogger.debug('RemoteConfig: инициализация уже выполняется');
      return;
    }

    try {
      _isPending = true;
      GmsLogger.debug('RemoteConfig: начало инициализации');

      await _firebaseRemoteConfig.setConfigSettings(_settings);
      await _firebaseRemoteConfig.fetchAndActivate();

      final data = _firebaseRemoteConfig.getAll();
      _logConfigData(data);

      _dataCompleter.complete(data);
      _isInitialized = true;

      GmsLogger.debug('RemoteConfig: успешно инициализирован');
    } catch (e, st) {
      _isInitialized = false;
      GmsLogger.error(
        'RemoteConfig: ошибка при инициализации',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } finally {
      _isPending = false;
    }
  }

  /// Получает строковое значение по ключу.
  String getString(String key) {
    _ensureInitialized();
    return _firebaseRemoteConfig.getString(key);
  }

  /// Получает числовое значение по ключу.
  int getInt(String key) {
    _ensureInitialized();
    return _firebaseRemoteConfig.getInt(key);
  }

  /// Получает булево значение по ключу.
  bool getBool(String key) {
    _ensureInitialized();
    return _firebaseRemoteConfig.getBool(key);
  }

  /// Получает значение типа double по ключу.
  double getDouble(String key) {
    _ensureInitialized();
    return _firebaseRemoteConfig.getDouble(key);
  }

  /// Получает все значения конфигурации.
  ///
  /// Возвращает пустую карту, если инициализация не выполнена.
  Map<String, dynamic> getAll() {
    if (!_isInitialized) {
      GmsLogger.warning(
        'RemoteConfig: попытка получить данные до инициализации',
      );
      return {};
    }
    return _firebaseRemoteConfig.getAll();
  }

  /// Ожидает завершения инициализации и возвращает все данные.
  ///
  /// Если инициализация уже завершена, возвращает кэшированные данные.
  Future<Map<String, dynamic>> getData() async {
    if (_isInitialized) {
      return _firebaseRemoteConfig.getAll();
    }
    return _dataCompleter.future;
  }

  /// Проверяет, инициализирован ли Remote Config.
  bool get isInitialized => _isInitialized;

  /// Проверяет, выполняется ли инициализация.
  bool get isPending => _isPending;

  /// Проверяет, что Remote Config инициализирован.
  ///
  /// Выбрасывает [StateError], если инициализация не выполнена.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'RemoteConfig не инициализирован. Вызовите initialize() перед использованием.',
      );
    }
  }

  /// Логирует все значения конфигурации.
  void _logConfigData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      GmsLogger.debug('RemoteConfig: конфигурация пуста');
      return;
    }

    GmsLogger.debug('RemoteConfig: загружено ${data.length} параметров');
    data.forEach((key, value) {
      GmsLogger.debug('RemoteConfig: $key = $value');
    });
  }
}
