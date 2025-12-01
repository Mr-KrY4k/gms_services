/// Публичный API для программной настройки и очистки Android проекта.
///
/// Этот модуль экспортирует функции setup и cleanup для удобного использования.
/// Вы можете импортировать этот модуль для доступа к обеим функциям.
library;

export 'src/setup_helper.dart' show SetupResult;
export 'src/gms_services_setup.dart' show setupGmsServices;
export 'src/gms_services_cleanup.dart' show cleanupGmsServices;
