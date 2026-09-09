import 'dart:convert';
import 'package:caminhandojuntos/config/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serviço base para comunicação segura com o Backend Java.
/// Garante o uso de HTTPS e tratamento centralizado de erros técnicos.
abstract class BaseApiService {
  final http.Client _client = http.Client();

  /// Realiza uma chamada GET segura.
  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return _processResponse(await _client.get(url).timeout(ApiConfig.timeout));
  }

  /// Realiza uma chamada POST segura.
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    return _processResponse(await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    ).timeout(ApiConfig.timeout));
  }

  /// Processa a resposta e esconde stack traces do Java.
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
        // Registra o erro real apenas no console de debug (logs não capturados em prod)
        debugPrint('API Error [${response.statusCode}]: ${response.body}');
        // Mensagem genérica para o usuário
        throw Exception('Servidor temporariamente indisponível. Tente mais tarde.');
    }
  }

  /// TODO: Adicionar Interceptor para injetar o Token JWT automaticamente no header Authorization.
}
