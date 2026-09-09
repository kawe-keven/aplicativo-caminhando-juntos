import 'package:caminhandojuntos/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de persistência local para os dados do usuário.
/// Escolhemos shared_preferences por ser ideal para dados simples de perfil
/// e configurações, oferecendo leitura/escrita rápida com baixo overhead.
class UserStorageService {
  static const String _userKey = 'user_data';

  /// Salva ou atualiza os dados do usuário localmente.
  /// // TODO: sincronizar com API quando houver backend
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, user.toJson());
  }

  /// Recupera o usuário salvo. Retorna null se não houver cadastro.
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Verifica de forma rápida se já existe um usuário cadastrado.
  Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }

  /// Limpa os dados do usuário (Logout/Reset).
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
