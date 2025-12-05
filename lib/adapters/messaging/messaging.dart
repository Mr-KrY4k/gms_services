import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../../consts.dart';
import '../../src/logger.dart';
import '../../src/storage/storage.dart';
import '../../src/storage/preferences_storage.dart';
import 'storage_keys.dart';

/// Колбек для обработки события блокировки пушей.
typedef OnPushBlockedCallback = void Function();

/// Адаптер для работы с Firebase Messaging.
///
/// Предоставляет упрощенный интерфейс для работы с push-уведомлениями,
/// включая инициализацию, обработку входящих сообщений и их хранение.
///
/// Пример использования:
/// ```dart
/// Messaging.instance.setOnPushBlockedCallback(() {
/// Обработка блокировки пушей
/// });
/// await Messaging.instance.init();
/// final token = await Messaging.instance.fcmToken;
/// ```
final class Messaging {
  Messaging._();

  /// Единственный экземпляр класса.
  static final Messaging instance = Messaging._();

  /// Экземпляр Firebase Messaging.
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Storage для хранения сообщений (Hive).
  late final Storage _storage = Storage(MessagingStorageKeys.pushMessagesBox);

  /// Хранилище для флагов и простых значений (SharedPreferences).
  final PreferencesStorage _prefs = PreferencesStorage.instance;

  /// Колбек для обработки блокировки пушей.
  OnPushBlockedCallback? _onPushBlockedCallback;

  /// Completer для получения FCM токена.
  final _fcmTokenCompleter = Completer<String>();

  /// Стрим контроллер для входящих сообщений.
  final _onMessageReceived = StreamController<RemoteMessage>.broadcast();

  /// Стрим контроллер для изменения статуса уведомлений.
  final _onNotificationStatusChanged =
      StreamController<AuthorizationStatus>.broadcast();

  /// Список всех полученных сообщений.
  final List<RemoteMessage> _messages = [];

  /// Статус уведомлений.
  AuthorizationStatus _notificationStatus = AuthorizationStatus.notDetermined;

  /// Флаг инициализации.
  bool _isInitialized = false;

  /// Флаг выполнения инициализации.
  bool _isPending = false;

  /// Получает FCM токен.
  ///
  /// Возвращает токен после завершения инициализации.
  Future<String> get fcmToken => _fcmTokenCompleter.future;

  /// Получает список всех сообщений.
  List<RemoteMessage> get messages => List.unmodifiable(_messages);

  /// Стрим входящих сообщений.
  Stream<RemoteMessage> get onMessageReceived => _onMessageReceived.stream;

  AuthorizationStatus get notificationStatus => _notificationStatus;

  /// Стрим изменения статуса уведомлений.
  Stream<AuthorizationStatus> get onNotificationStatusChanged =>
      _onNotificationStatusChanged.stream;

  /// Устанавливает колбек для обработки блокировки пушей.
  ///
  /// [callback] - функция, которая будет вызвана при блокировке пушей.
  void setOnPushBlockedCallback(OnPushBlockedCallback? callback) {
    _onPushBlockedCallback = callback;
  }

  /// Инициализирует Messaging.
  ///
  /// Запрашивает разрешения, настраивает слушатели сообщений,
  /// загружает сохраненные сообщения и получает FCM токен.
  /// Метод безопасен для повторного вызова - повторная инициализация
  /// будет пропущена, если уже выполняется или завершена.
  ///
  /// Выбрасывает исключение, если инициализация не удалась.
  Future<void> init() async {
    if (_isInitialized) {
      GmsLogger.debug('Messaging: уже инициализирован');
      return;
    }

    if (_isPending) {
      GmsLogger.debug('Messaging: инициализация уже выполняется');
      return;
    }

    try {
      _isPending = true;
      GmsLogger.debug('Messaging: начало инициализации');

      await _storage.init();
      await _requestPermission();
      await _loadStoredMessages();
      await checkNotificationStatus();

      final token = await _firebaseMessaging.getToken();
      final fcmToken = token ?? Consts.notAvailable;
      _fcmTokenCompleter.complete(fcmToken);
      GmsLogger.debug('Messaging: FCM токен получен: $fcmToken');

      await _handleInitialMessage();
      await _setupMessageListeners();

      _isInitialized = true;
      GmsLogger.debug('Messaging: успешно инициализирован');
    } catch (e, st) {
      _isInitialized = false;
      GmsLogger.error(
        'Messaging: ошибка при инициализации',
        error: e,
        stackTrace: st,
      );
      if (!_fcmTokenCompleter.isCompleted) {
        _fcmTokenCompleter.complete(Consts.notAvailable);
      }
      rethrow;
    } finally {
      _isPending = false;
    }
  }

  /// Запрашивает разрешение на уведомления.
  Future<void> _requestPermission() async {
    try {
      final alreadyRequested =
          await _prefs.getBool(
            MessagingStorageKeys.firstPushRequestPermission,
          ) ??
          false;
      if (!alreadyRequested) {
        await _prefs.setBool(
          MessagingStorageKeys.firstPushRequestPermission,
          true,
        );
      }

      await _firebaseMessaging.requestPermission();
      GmsLogger.debug('Messaging: разрешение запрошено');
      await checkNotificationStatus();
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при запросе разрешения',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Загружает сохраненные сообщения из storage.
  Future<void> _loadStoredMessages() async {
    try {
      final allMessages = _storage.getAll();
      _messages.clear();

      for (final messageMap in allMessages) {
        try {
          final message = RemoteMessage.fromMap(messageMap);
          _messages.add(message);
        } catch (e, st) {
          GmsLogger.error(
            'Messaging: ошибка при загрузке сообщения из storage',
            error: e,
            stackTrace: st,
          );
        }
      }

      GmsLogger.debug('Messaging: загружено ${_messages.length} сообщений');
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при загрузке сохраненных сообщений',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Сохраняет входящее сообщение в storage.
  Future<void> _saveMessage(RemoteMessage message) async {
    try {
      final messageId =
          message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final messageMap = message.toMap();
      await _storage.save(messageId, messageMap);
      GmsLogger.debug('Messaging: сообщение сохранено: $messageId');
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при сохранении сообщения',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Обрабатывает входящее сообщение.
  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    try {
      GmsLogger.debug('Messaging: получено сообщение: ${message.messageId}');

      _onMessageReceived.add(message);
      _messages.add(message);
      await _saveMessage(message);
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при обработке входящего сообщения',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Обрабатывает входящее сообщение с открытием приложения.
  Future<void> _handleIncomingMessageWithOpen(RemoteMessage message) async {
    await _handleIncomingMessage(message);
    await _saveLastPushOpenMeta(message);
  }

  /// Обрабатывает начальное сообщение (когда приложение открыто из уведомления).
  Future<void> _handleInitialMessage() async {
    try {
      final message = await _firebaseMessaging.getInitialMessage();
      if (message != null) {
        await _handleIncomingMessageWithOpen(message);
      }
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при обработке начального сообщения',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Настраивает слушатели сообщений.
  Future<void> _setupMessageListeners() async {
    try {
      FirebaseMessaging.onMessage.listen(_handleIncomingMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleIncomingMessageWithOpen,
      );
      GmsLogger.debug('Messaging: слушатели сообщений настроены');
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при настройке слушателей',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Сохраняет метаданные последнего открытого пуша.
  Future<void> _saveLastPushOpenMeta(RemoteMessage message) async {
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final messageId = message.messageId ?? 'unknown';

      await _prefs.setInt(MessagingStorageKeys.lastPushOpenTime, currentTime);
      await _prefs.setString(
        MessagingStorageKeys.lastPushOpenMessageId,
        messageId,
      );
      await _prefs.setBool(MessagingStorageKeys.lastPushOpenViewed, false);

      GmsLogger.debug(
        'Messaging: сохранены метаданные последнего пуша: time=$currentTime, id=$messageId',
      );
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при сохранении метаданных последнего пуша',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Получает время последнего открытия пуша.
  Future<DateTime?> _getLastPushOpenTime() async {
    try {
      final timestamp = await _prefs.getInt(
        MessagingStorageKeys.lastPushOpenTime,
      );
      if (timestamp != null) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        GmsLogger.debug('Messaging: время последнего открытия: $dateTime');
        return dateTime;
      }
      return null;
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при получении времени последнего открытия',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Получает ID последнего открытого сообщения.
  Future<String?> _getLastPushOpenMessageId() async {
    try {
      final id = await _prefs.getString(
        MessagingStorageKeys.lastPushOpenMessageId,
      );
      return id;
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при получении ID последнего сообщения',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Проверяет, было ли приложение открыто через пуш.
  Future<bool> wasAppOpenedByPush() async {
    final lastOpenTime = await _getLastPushOpenTime();
    return lastOpenTime != null;
  }

  /// Проверяет, просмотрен ли последний открытый пуш.
  Future<bool> isLastOpenedPushViewed() async {
    try {
      final viewed = await _prefs.getBool(
        MessagingStorageKeys.lastPushOpenViewed,
      );
      return viewed == true;
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при проверке статуса просмотра',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Отмечает последний открытый пуш как просмотренный.
  Future<void> markLastOpenedPushAsViewed() async {
    try {
      await _prefs.setBool(MessagingStorageKeys.lastPushOpenViewed, true);
      final messageId = await _getLastPushOpenMessageId();
      GmsLogger.debug(
        'Messaging: последний пуш отмечен как просмотренный: id=${messageId ?? 'unknown'}',
      );
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при отметке пуша как просмотренного',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Проверяет, было ли приложение открыто через пуш и просмотрен ли он.
  Future<bool> wasAppOpenedByPushAndViewed() async {
    final opened = await wasAppOpenedByPush();
    if (!opened) return false;
    return await isLastOpenedPushViewed();
  }

  /// Проверяет, находится ли последнее открытие пуша в пределах 24 часов.
  Future<bool> isWithin24HoursFromPushOpen() async {
    final lastOpenTime = await _getLastPushOpenTime();
    if (lastOpenTime == null) {
      return false;
    }

    final now = DateTime.now();
    final difference = now.difference(lastOpenTime);
    final isWithin24Hours = difference.inHours < 24;

    GmsLogger.debug(
      'Messaging: последнее открытие: $lastOpenTime, сейчас: $now, разница: ${difference.inHours}ч, в пределах 24ч: $isWithin24Hours',
    );

    return isWithin24Hours;
  }

  /// Проверяет, находится ли последнее открытие пуша в пределах 24 часов и просмотрен ли он.
  Future<bool> isWithin24HoursFromPushOpenAndViewed() async {
    final within24 = await isWithin24HoursFromPushOpen();
    if (!within24) return false;
    return await isLastOpenedPushViewed();
  }

  /// Получает последний открытый пуш в пределах 24 часов.
  Future<RemoteMessage?> getLastOpenedPushWithin24Hours() async {
    final lastOpenTime = await _getLastPushOpenTime();
    if (lastOpenTime == null) return null;

    if (DateTime.now().difference(lastOpenTime) >= const Duration(hours: 24)) {
      return null;
    }

    final messageId = await _getLastPushOpenMessageId();
    if (messageId == null || messageId.isEmpty) return null;

    for (final message in _messages) {
      if (message.messageId == messageId) {
        return message;
      }
    }

    try {
      final allMessages = _storage.getAll();
      for (final messageMap in allMessages) {
        try {
          final message = RemoteMessage.fromMap(messageMap);
          if (message.messageId == messageId) {
            return message;
          }
        } catch (e) {
          // Пропускаем некорректные сообщения
        }
      }
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при поиске последнего открытого пуша',
        error: e,
        stackTrace: st,
      );
    }

    return null;
  }

  /// Проверяет статус уведомлений.
  Future<void> checkNotificationStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      _notificationStatus = settings.authorizationStatus;
      _onNotificationStatusChanged.add(_notificationStatus);

      // Вызываем колбек при блокировке (только если это не первый запрос)
      final firstRequest = await _prefs.getBool(
        MessagingStorageKeys.firstPushRequestPermission,
      );
      if (firstRequest == true &&
          _notificationStatus == AuthorizationStatus.denied) {
        _onPushBlockedCallback?.call();
      }

      GmsLogger.debug('Messaging: статус уведомлений: $_notificationStatus');
    } catch (e, st) {
      GmsLogger.error(
        'Messaging: ошибка при проверке статуса уведомлений',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Проверяет, инициализирован ли Messaging.
  bool get isInitialized => _isInitialized;

  /// Проверяет, выполняется ли инициализация.
  bool get isPending => _isPending;
}
