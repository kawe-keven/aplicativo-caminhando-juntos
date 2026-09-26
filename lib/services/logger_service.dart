import 'package:flutter/foundation.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Serviço de log centralizado. 
class AppLogger {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// REGRA: Nunca engolir erros. Em release, reporta ao serviço de crash reporting (Firebase Crashlytics / Sentry).
  static void e(String message, [dynamic error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('Caused by: $error');
    }
    if (stack != null) {
      debugPrint('Stacktrace: $stack');
    }

    if (!kDebugMode) {
      // TODO(crashlytics): Ativar em produção após configurar google-services.json / GoogleService-Info.plist
      // try {
      //   FirebaseCrashlytics.instance.recordError(error ?? message, stack, reason: message);
      // } catch (_) {}
    }
  }
}
