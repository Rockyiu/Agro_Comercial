import 'dart:convert';

class UserModel {
  final String? id;
  final String? name;
  final String? email;
  final String? cpf;
  final String? password;
  final String? role;
  final String? phone;
  final String? managerId; // O ID do gerente dono da fazenda
  // Colaborador liberado pelo produtor para registrar Produção/Colheita.
  // Só é gravado pela tela "Minha Equipe" (EmployeeService), por isso fica
  // fora do toMap: salvar o perfil não pode apagar nem alterar a liberação.
  final bool canRegisterHarvest;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.password,
    required this.role,
    this.phone,
    this.managerId,
    this.canRegisterHarvest = false,
  });

  bool get isCollaborator => role == 'colaborador';

  UserModel copyWith({bool? canRegisterHarvest}) {
    return UserModel(
      id: id,
      name: name,
      email: email,
      cpf: cpf,
      password: password,
      role: role,
      phone: phone,
      managerId: managerId,
      canRegisterHarvest: canRegisterHarvest ?? this.canRegisterHarvest,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'role': role,
      'phone': phone,
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
      managerId: map['managerId'] != null ? map['managerId'] as String : null,
      canRegisterHarvest: map['canRegisterHarvest'] == true,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
