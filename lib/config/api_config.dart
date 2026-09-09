class ApiConfig {
  // Endereço do backend Java (HTTPS obrigatório para produção)
  // TODO: Alterne para a URL real de produção quando disponível
  static const String baseUrl = 'https://api.caminhajuntos.com.br/v1';
  
  // Timeout padrão para chamadas de rede
  static const Duration timeout = Duration(seconds: 15);

  // Chaves de API (Devem ser injetadas via --dart-define no build de produção)
  // static const String apiKey = String.fromEnvironment('API_KEY');
}
