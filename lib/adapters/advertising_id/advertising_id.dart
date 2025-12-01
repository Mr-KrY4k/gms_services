import 'package:advertising_id/advertising_id.dart' as advertising_id_pkg;

import '../../consts.dart';
import '../../src/logger.dart';

/// Адаптер для работы с Advertising ID.
///
/// Предоставляет упрощенный интерфейс для получения рекламного идентификатора
/// устройства и статуса ограничения отслеживания.
///
/// Пример использования:
/// ```dart
/// final id = await AdvertisingIdAdapter.instance.id;
/// final isLimitAdTrackingEnabled =
///     await AdvertisingIdAdapter.instance.isLimitAdTrackingEnabled;
/// ```
final class AdvertisingIdAdapter {
  AdvertisingIdAdapter._();

  /// Единственный экземпляр класса.
  static final AdvertisingIdAdapter instance = AdvertisingIdAdapter._();

  /// Кэшированное значение Advertising ID.
  String? _cachedId;

  /// Кэшированное значение статуса ограничения отслеживания.
  bool? _cachedLimitAdTracking;

  /// Флаг выполнения запроса ID.
  bool _isIdPending = false;

  /// Флаг выполнения запроса статуса ограничения отслеживания.
  bool _isLimitPending = false;

  /// Получает Advertising ID.
  ///
  /// В случае ошибки возвращает [Consts.notAvailable].
  Future<String> get id async {
    if (_cachedId != null) {
      return _cachedId!;
    }

    if (_isIdPending) {
      // Ждем завершения первого запроса
      while (_isIdPending) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedId ?? Consts.notAvailable;
    }

    try {
      _isIdPending = true;
      GmsLogger.debug('AdvertisingIdAdapter: запрос Advertising ID');

      final value = await advertising_id_pkg.AdvertisingId.id(true);
      _cachedId = value ?? Consts.notAvailable;

      GmsLogger.debug('AdvertisingIdAdapter: Advertising ID = $_cachedId');
      return _cachedId!;
    } catch (e, st) {
      GmsLogger.error(
        'AdvertisingIdAdapter: ошибка при получении Advertising ID',
        error: e,
        stackTrace: st,
      );
      _cachedId = Consts.notAvailable;
      return _cachedId!;
    } finally {
      _isIdPending = false;
    }
  }

  /// Проверяет, включено ли ограничение отслеживания (Limit Ad Tracking).
  ///
  /// В случае ошибки возвращает `false`.
  Future<bool> get isLimitAdTrackingEnabled async {
    if (_cachedLimitAdTracking != null) {
      return _cachedLimitAdTracking!;
    }

    if (_isLimitPending) {
      // Ждем завершения первого запроса
      while (_isLimitPending) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedLimitAdTracking ?? false;
    }

    try {
      _isLimitPending = true;
      GmsLogger.debug('AdvertisingIdAdapter: запрос статуса Limit Ad Tracking');

      final value =
          await advertising_id_pkg.AdvertisingId.isLimitAdTrackingEnabled;
      _cachedLimitAdTracking = value ?? false;

      GmsLogger.debug(
        'AdvertisingIdAdapter: Limit Ad Tracking = $_cachedLimitAdTracking',
      );
      return _cachedLimitAdTracking!;
    } catch (e, st) {
      GmsLogger.error(
        'AdvertisingIdAdapter: ошибка при получении статуса Limit Ad Tracking',
        error: e,
        stackTrace: st,
      );
      _cachedLimitAdTracking = false;
      return _cachedLimitAdTracking!;
    } finally {
      _isLimitPending = false;
    }
  }
}
