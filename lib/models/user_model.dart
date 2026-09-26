import 'dart:convert';

class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
      };

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class UserModel {
  final String name;
  final int age;
  final List<EmergencyContact> emergencyContacts;
  final bool isRegistered;

  UserModel({
    this.name = '',
    this.age = 60,
    List<EmergencyContact>? emergencyContacts,
    this.isRegistered = false,
  }) : emergencyContacts = emergencyContacts ?? [];

  // Getters de compatibilidade com código legado
  String get emergencyContactName => emergencyContacts.isNotEmpty ? emergencyContacts.first.name : '';
  String get emergencyContactPhone => emergencyContacts.isNotEmpty ? emergencyContacts.first.phone : '';
  String get emergencyContact => emergencyContacts.isNotEmpty ? "${emergencyContacts.first.name} - ${emergencyContacts.first.phone}" : "";

  UserModel copyWith({
    String? name,
    int? age,
    List<EmergencyContact>? emergencyContacts,
    bool? isRegistered,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
      'isRegistered': isRegistered,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    List<EmergencyContact> contacts = [];
    if (map['emergencyContacts'] != null) {
      contacts = (map['emergencyContacts'] as List)
          .map((c) => EmergencyContact.fromMap(c as Map<String, dynamic>))
          .toList();
    } else {
      // Migração de dados legados do formato antigo de contato único
      final oldName = map['emergencyContactName'] as String?;
      final oldPhone = map['emergencyContactPhone'] as String?;
      if (oldName != null && oldName.isNotEmpty) {
        contacts.add(EmergencyContact(name: oldName, phone: oldPhone ?? ''));
      }
    }
    return UserModel(
      name: map['name'] ?? '',
      age: map['age'] ?? 60,
      emergencyContacts: contacts,
      isRegistered: map['isRegistered'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}
