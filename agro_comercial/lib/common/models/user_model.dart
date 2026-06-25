import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? cpf;
  final String? password;
  final String? role;
  final String? phone;
  final String? imageUrl;
  final String? managerId; // ADICIONADO: O ID do gerente dono da fazenda

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.password,
    required this.role,
    this.phone,
    this.imageUrl,
    this.managerId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'role': role,
      'phone': phone,
      'imageUrl': imageUrl,
      'managerId': managerId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      email: map['email'] != null ? map['email'] as String : null,
      cpf: (map['cpf'] ?? map['CPF'] ?? map['Cpf']) as String?,
      password: map['password'] != null ? map['password'] as String : null,
      role: map['role'] != null ? map['role'] as String : null,
      phone: map['phone'] != null ? map['phone'] as String : null,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      managerId: map['managerId'] != null ? map['managerId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
