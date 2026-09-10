import 'package:caminhandojuntos/models/user_model.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de persistência local para os dados do usuário.
/// Refatorado para seguir critérios de segurança: dados sensíveis vão para SecureStorage.
class UserStorageService {
  final SecureStorageService _secureStorage = SecureStorageService();
  static const String _userProfileKey = 'secure_user_profile';
  static const String _appSettingsKey = 'app_onboarding_done';

  /// Salva os dados do usuário de forma criptografada.
  Future<void> saveUser(UserModel user) async {
    // Dados Sensíveis -> Secure Storage
    await _secureStorage.write(_userProfileKey, user.toJson());
    
    // Metadados não sensíveis -> SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appSettingsKey, user.isRegistered);
  }

  /// Recupera o usuário salvo do armazenamento criptografado.
  Future<UserModel?> getUser() async {
    final userJson = await _secureStorage.read(_userProfileKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(userJson);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Verifica se o cadastro existe (checa preferência não sensível primeiro por performance).
  Future<bool> hasUser() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(_appSettingsKey) ?? false;
    if (!onboardingDone) return false;
    
    // Confirma se o dado real existe no storage seguro
    final userJson = await _secureStorage.read(_userProfileKey);
    return userJson != null;
  }

  /// Limpa os dados do usuário (Logout/Reset).
  Future<void> clearUser() async {
    await _secureStorage.delete(_userProfileKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appSettingsKey);
  }
}
