class ApiConfig {
  // Endereço do backend Java (HTTPS obrigatório para produção)
  // Sobrescritível via --dart-define=BACKEND_URL=...
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://api.caminhandojuntos.com.br/v1',
  );
  
  // Timeout padrão para chamadas de rede
  static const Duration timeout = Duration(seconds: 15);
}
