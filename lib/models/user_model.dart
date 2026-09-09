import 'dart:convert';

class UserModel {
  final String name;
  final int age;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool isRegistered;

  UserModel({
    this.name = '',
    this.age = 60,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.isRegistered = false,
  });

  String get emergencyContact => "$emergencyContactName - $emergencyContactPhone";

  UserModel copyWith({
    String? name,
    int? age,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isRegistered,
  }) {
    return UserModel(
      name: name ?? this.name,
      age: age ?? this.age,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'isRegistered': isRegistered,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      age: map['age'] ?? 60,
      emergencyContactName: map['emergencyContactName'] ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] ?? '',
      isRegistered: map['isRegistered'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}
