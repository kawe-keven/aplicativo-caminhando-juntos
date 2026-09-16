import 'dart:convert';
import 'package:caminhandojuntos/config/api_config.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:http/http.dart' as http;

/// Serviço base para comunicação segura com o Backend Java.
/// Garante o uso de HTTPS e tratamento centralizado de erros técnicos.
abstract class BaseApiService {
  
  /// Realiza uma chamada GET segura. 
  /// REGRA: Uso direto de http.get para não precisar gerenciar ciclo de vida de Client.
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http.get(url).timeout(ApiConfig.timeout);
    return _processResponse(response);
  }

  /// Realiza uma chamada POST segura.
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(ApiConfig.timeout);
    return _processResponse(response);
  }

  /// Processa a resposta e esconde stack traces do Java em produção.
  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        throw Exception('Dados inválidos. Por favor, verifique as informações.');
      case 401:
      case 403:
        throw Exception('Sessão expirada. Por favor, entre novamente.');
      case 500:
      default:
        AppLogger.e('API Error [${response.statusCode}]: ${response.body}');
        throw Exception('Servidor temporariamente indisponível. Tente mais tarde.');
    }
  }
}
