import 'package:flutter/foundation.dart';

/// Serviço de log centralizado. 
class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// REGRA: Nunca engolir erros. Em release, usar debugPrint para rastreio básico
  /// ou integrar com ferramentas como Sentry/Firebase Crashlytics.
  static void e(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Caused by: $error');
    }
    if (stack != null) {
      debugPrint('Stacktrace: $stack');
    }
  }
}
