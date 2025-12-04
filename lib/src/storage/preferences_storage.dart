import 'package:shared_preferences/shared_preferences.dart';

import '../logger.dart';

/// Обертка над SharedPreferences для хранения простых настроек.
///
/// Используется для хранения флагов и простых значений, связанных
/// с работой плагина (кроме самих push-сообщений, которые
/// хранятся в Hive).
final class PreferencesStorage {
  PreferencesStorage._();

  /// Единственный экземпляр класса.
  static final PreferencesStorage instance = PreferencesStorage._();

  SharedPreferences? _prefs;
  bool _isInitializing = false;

  /// Гарантирует, что SharedPreferences инициализирован.
  Future<void> _ensureInitialized() async {
    if (_prefs != null) return;
    if (_isInitializing) {
      // Ждем завершения текущей инициализации
      while (_isInitializing && _prefs == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    try {
      _isInitializing = true;
      GmsLogger.debug('PreferencesStorage: начало инициализации');
      _prefs = await SharedPreferences.getInstance();
      GmsLogger.debug('PreferencesStorage: успешно инициализирован');
    } catch (e, st) {
      GmsLogger.error(
        'PreferencesStorage: ошибка при инициализации',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Сохраняет булево значение.
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return _prefs!.setBool(key, value);
  }

  /// Получает булево значение.
  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    return _prefs!.getBool(key);
  }

  /// Сохраняет целочисленное значение.
  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return _prefs!.setInt(key, value);
  }

  /// Получает целочисленное значение.
  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    return _prefs!.getInt(key);
  }

  /// Сохраняет строковое значение.
  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return _prefs!.setString(key, value);
  }

  /// Получает строковое значение.
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    return _prefs!.getString(key);
  }
}
