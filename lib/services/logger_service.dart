import 'package:flutter/foundation.dart';

/// Serviço de log centralizado para garantir que dados sensíveis não vazem em produção.
class AppLogger {
  /// Registra uma mensagem técnica apenas em modo debug.
  static void d(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[DEBUG] $message');
    }
  }

  /// Registra um erro apenas em modo debug.
  static void e(String message, [dynamic error, StackTrace? stack]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[ERROR] $message');
      if (error != null) {
        // ignore: avoid_print
        print('Caused by: $error');
      }
      if (stack != null) {
        // ignore: avoid_print
        print('Stacktrace: $stack');
      }
    }
  }

  /// REGRA DE SEGURANÇA: Nunca logue variáveis que contenham dados de perfil do usuário.
}
