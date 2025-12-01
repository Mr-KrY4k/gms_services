import 'adapters/analytics/analytics.dart';
import 'adapters/messaging/messaging.dart';
import 'adapters/remote_config/remote_config.dart';
import 'src/logger.dart';

/// Результат инициализации GMS сервисов.
class GmsServicesInitResult {
  /// Создает результат инициализации.
  GmsServicesInitResult({
    required this.success,
    required this.analytics,
    required this.remoteConfig,
    required this.messaging,
    this.errors,
  });

  /// Общий успех инициализации (все сервисы инициализированы).
  final bool success;

  /// Результат инициализации Analytics.
  final bool analytics;

  /// Результат инициализации Remote Config.
  final bool remoteConfig;

  /// Результат инициализации Messaging.
  final bool messaging;

  /// Список ошибок, если они были.
  final List<String>? errors;

  /// Получает список всех ошибок.
  List<String> get allErrors {
    final errorsList = <String>[];
    if (errors != null) {
      errorsList.addAll(errors!);
    }
    return errorsList;
  }
}

/// Главный сервис для работы с Google Mobile Services.
///
/// Предоставляет единую точку входа для инициализации всех адаптеров:
/// Analytics, Remote Config и Messaging.
///
/// Пример использования:
/// ```dart
/// final result = await GmsServices.instance.init();
/// if (result.success) {
///   print('Все сервисы инициализированы');
/// } else {
///   print('Ошибки: ${result.allErrors}');
/// }
/// ```
final class GmsServices {
  GmsServices._();

  /// Единственный экземпляр класса.
  static final GmsServices instance = GmsServices._();

  /// Флаг инициализации.
  bool _isInitialized = false;

  /// Флаг выполнения инициализации.
  bool _isPending = false;

  /// Инициализирует все GMS сервисы.
  ///
  /// Инициализирует Analytics, Remote Config и Messaging.
  /// Метод безопасен для повторного вызова - повторная инициализация
  /// будет пропущена, если уже выполняется или завершена.
  ///
  /// [onPushBlocked] - опциональный колбек для обработки блокировки пушей.
  ///
  /// Возвращает [GmsServicesInitResult] с результатами инициализации каждого сервиса.
  Future<GmsServicesInitResult> init({void Function()? onPushBlocked}) async {
    if (_isInitialized) {
      GmsLogger.debug('GmsServices: уже инициализирован');
      return _createResult(
        analytics: Analytics.instance.isInitialized,
        remoteConfig: RemoteConfig.instance.isInitialized,
        messaging: Messaging.instance.isInitialized,
      );
    }

    if (_isPending) {
      GmsLogger.debug('GmsServices: инициализация уже выполняется');
      // Ждем завершения текущей инициализации
      while (_isPending) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _createResult(
        analytics: Analytics.instance.isInitialized,
        remoteConfig: RemoteConfig.instance.isInitialized,
        messaging: Messaging.instance.isInitialized,
      );
    }

    try {
      _isPending = true;
      GmsLogger.debug('GmsServices: начало инициализации');

      // Устанавливаем колбек для Messaging, если передан
      if (onPushBlocked != null) {
        Messaging.instance.setOnPushBlockedCallback(onPushBlocked);
      }

      final errors = <String>[];
      bool analyticsSuccess = false;
      bool remoteConfigSuccess = false;
      bool messagingSuccess = false;

      // Инициализация Analytics
      try {
        await Analytics.instance.init();
        analyticsSuccess = true;
        GmsLogger.debug('GmsServices: Analytics инициализирован');
      } catch (e, st) {
        errors.add('Analytics: $e');
        GmsLogger.error(
          'GmsServices: ошибка при инициализации Analytics',
          error: e,
          stackTrace: st,
        );
      }

      // Инициализация Remote Config
      try {
        await RemoteConfig.instance.initialize();
        remoteConfigSuccess = true;
        GmsLogger.debug('GmsServices: Remote Config инициализирован');
      } catch (e, st) {
        errors.add('Remote Config: $e');
        GmsLogger.error(
          'GmsServices: ошибка при инициализации Remote Config',
          error: e,
          stackTrace: st,
        );
      }

      // Инициализация Messaging
      try {
        await Messaging.instance.init();
        messagingSuccess = true;
        GmsLogger.debug('GmsServices: Messaging инициализирован');
      } catch (e, st) {
        errors.add('Messaging: $e');
        GmsLogger.error(
          'GmsServices: ошибка при инициализации Messaging',
          error: e,
          stackTrace: st,
        );
      }

      final success =
          analyticsSuccess && remoteConfigSuccess && messagingSuccess;
      _isInitialized = success;

      final result = GmsServicesInitResult(
        success: success,
        analytics: analyticsSuccess,
        remoteConfig: remoteConfigSuccess,
        messaging: messagingSuccess,
        errors: errors.isEmpty ? null : errors,
      );

      if (success) {
        GmsLogger.debug('GmsServices: все сервисы успешно инициализированы');
      } else {
        GmsLogger.warning(
          'GmsServices: инициализация завершена с ошибками: ${errors.length}',
        );
      }

      return result;
    } finally {
      _isPending = false;
    }
  }

  /// Создает результат инициализации на основе текущего состояния.
  GmsServicesInitResult _createResult({
    required bool analytics,
    required bool remoteConfig,
    required bool messaging,
  }) {
    return GmsServicesInitResult(
      success: analytics && remoteConfig && messaging,
      analytics: analytics,
      remoteConfig: remoteConfig,
      messaging: messaging,
    );
  }

  /// Проверяет, инициализированы ли все сервисы.
  bool get isInitialized => _isInitialized;

  /// Проверяет, выполняется ли инициализация.
  bool get isPending => _isPending;

  /// Получает экземпляр Analytics.
  Analytics get analytics => Analytics.instance;

  /// Получает экземпляр Remote Config.
  RemoteConfig get remoteConfig => RemoteConfig.instance;

  /// Получает экземпляр Messaging.
  Messaging get messaging => Messaging.instance;
}
