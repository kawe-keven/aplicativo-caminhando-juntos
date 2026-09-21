class UiTexts {
  static const String finishDialogTitle = "Deseja finalizar a caminhada?";
  static const String finishDialogYes = "Sim";
  static const String finishDialogNo = "Não";
  static const String walkFinishedMessage = "Caminhada finalizada!";
  
  static const String errorGpsDisabled = "GPS desativado. Por favor, ligue a localização.";
  static const String errorPermissionDenied = "Permissão de localização negada.";
  static const String errorPermissionDeniedPermanent = "Permissão negada permanentemente. Ajuste nas configurações.";
  static const String errorLocalDb = "Falha técnica ao salvar dados localmente.";
  static const String errorUnexpectedGps = "Erro inesperado ao iniciar GPS.";
  static const String errorDefault = "Ocorreu um erro inesperado.";

  // Mapeamento de mensagens internas para amigáveis
  static String messageForUser(String? code) {
    if (code == null) return "Falha de conexão com o sinal de GPS.";
    switch (code) {
      case "offline_sync_pending":
        return walkFinishedMessage;
      case "gps_disabled":
        return errorGpsDisabled;
      case "permission_denied":
        return errorPermissionDenied;
      case "permission_denied_permanent":
        return errorPermissionDeniedPermanent;
      case "local_db_error":
        return errorLocalDb;
      case "unexpected_gps_error":
        return errorUnexpectedGps;
      default:
        // Se o código for uma frase já em português (legado), retorna ela mesma
        if (code.contains(' ')) return code;
        return errorDefault;
    }
  }
}
