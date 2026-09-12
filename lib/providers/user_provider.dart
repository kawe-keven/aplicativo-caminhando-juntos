import 'package:caminhandojuntos/models/user_model.dart';
import 'package:caminhandojuntos/services/user_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final userStorageServiceProvider = Provider((ref) => UserStorageService());

final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  final storage = ref.watch(userStorageServiceProvider);
  return UserNotifier(storage);
});

class UserNotifier extends StateNotifier<UserModel> {
  final UserStorageService _storage;

  UserNotifier(this._storage) : super(UserModel());

  /// Inicializa o estado do usuário a partir do cache local.
  Future<void> init() async {
    final user = await _storage.getUser();
    if (user != null) {
      state = user;
    }
  }

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAge(int age) {
    if (age >= 0 && age <= 130) {
      state = state.copyWith(age: age);
    }
  }

  void updateEmergencyContactName(String name) {
    state = state.copyWith(emergencyContactName: name);
  }

  void updateEmergencyContactPhone(String phone) {
    state = state.copyWith(emergencyContactPhone: phone);
  }

  /// Finaliza o cadastro e salva no disco.
  Future<void> completeRegistration() async {
    // REGRA SOS: Solicita permissão de ligação no momento do cadastro
    await Permission.phone.request();
    
    state = state.copyWith(isRegistered: true);
    await _storage.saveUser(state);
  }

  /// Atualiza dados existentes (perfil).
  Future<void> updateUser() async {
    // Garante que a permissão foi solicitada ao atualizar contatos
    await Permission.phone.request();
    await _storage.saveUser(state);
  }

  /// Reseta o usuário (Logout).
  Future<void> logout() async {
    await _storage.clearUser();
    state = UserModel();
  }

  bool isFormValid() {
    return state.name.trim().isNotEmpty && 
           state.emergencyContactName.trim().isNotEmpty &&
           state.emergencyContactPhone.trim().length >= 10;
  }
}
