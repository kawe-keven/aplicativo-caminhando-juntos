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

  void updateEmergencyContacts(List<EmergencyContact> contacts) {
    state = state.copyWith(emergencyContacts: contacts);
  }

  void addEmergencyContact(EmergencyContact contact) {
    if (state.emergencyContacts.length < 3) {
      state = state.copyWith(emergencyContacts: [...state.emergencyContacts, contact]);
    }
  }

  void removeEmergencyContact(int index) {
    final list = List<EmergencyContact>.from(state.emergencyContacts);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(emergencyContacts: list);
    }
  }

  void updateEmergencyContactName(String name) {
    final contacts = List<EmergencyContact>.from(state.emergencyContacts);
    if (contacts.isNotEmpty) {
      contacts[0] = EmergencyContact(name: name, phone: contacts[0].phone);
    } else {
      contacts.add(EmergencyContact(name: name, phone: ''));
    }
    state = state.copyWith(emergencyContacts: contacts);
  }

  void updateEmergencyContactPhone(String phone) {
    final contacts = List<EmergencyContact>.from(state.emergencyContacts);
    if (contacts.isNotEmpty) {
      contacts[0] = EmergencyContact(name: contacts[0].name, phone: phone);
    } else {
      contacts.add(EmergencyContact(name: '', phone: phone));
    }
    state = state.copyWith(emergencyContacts: contacts);
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
           state.emergencyContacts.isNotEmpty &&
           state.emergencyContacts.first.name.trim().isNotEmpty &&
           state.emergencyContacts.first.phone.trim().length >= 10;
  }
}
