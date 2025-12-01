import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

import '../../consts.dart';
import '../../src/logger.dart';

/// Адаптер для работы с Firebase Analytics.
///
/// Предоставляет упрощенный интерфейс для инициализации и получения
/// идентификатора экземпляра приложения из Firebase Analytics.
///
/// Пример использования:
/// ```dart
/// await Analytics.instance.init();
/// final instanceId = await Analytics.instance.appInstanceId;
/// ```
final class Analytics {
  Analytics._();

  /// Единственный экземпляр класса.
  static final Analytics instance = Analytics._();

  /// Completer для получения идентификатора экземпляра приложения.
  final _appInstanceIdCompleter = Completer<String>();

  /// Флаг инициализации.
  bool _isInitialized = false;

  /// Флаг выполнения инициализации.
  bool _isPending = false;

  /// Получает идентификатор экземпляра приложения.
  ///
  /// Возвращает идентификатор после завершения инициализации.
  /// Если инициализация не была выполнена, ожидает её завершения.
  Future<String> get appInstanceId => _appInstanceIdCompleter.future;

  /// Инициализирует Analytics.
  ///
  /// Получает идентификатор экземпляра приложения из Firebase Analytics.
  /// Метод безопасен для повторного вызова - повторная инициализация
  /// будет пропущена, если уже выполняется или завершена.
  ///
  /// Выбрасывает исключение, если инициализация не удалась.
  Future<void> init() async {
    if (_isInitialized) {
      GmsLogger.debug('Analytics: уже инициализирован');
      return;
    }

    if (_isPending) {
      GmsLogger.debug('Analytics: инициализация уже выполняется');
      return;
    }

    try {
      _isPending = true;
      GmsLogger.debug('Analytics: начало инициализации');

      final appInstanceId = await FirebaseAnalytics.instance.appInstanceId;
      final instanceId = appInstanceId ?? Consts.notAvailable;

      _appInstanceIdCompleter.complete(instanceId);
      _isInitialized = true;

      GmsLogger.debug('Analytics: appInstanceId: $instanceId');
      GmsLogger.debug('Analytics: успешно инициализирован');
    } catch (e, st) {
      _isInitialized = false;
      GmsLogger.error(
        'Analytics: ошибка при инициализации',
        error: e,
        stackTrace: st,
      );
      _appInstanceIdCompleter.complete(Consts.notAvailable);
      rethrow;
    } finally {
      _isPending = false;
    }
  }

  /// Проверяет, инициализирован ли Analytics.
  bool get isInitialized => _isInitialized;

  /// Проверяет, выполняется ли инициализация.
  bool get isPending => _isPending;
}
