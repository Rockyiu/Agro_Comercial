import 'dart:convert';

class MachineModel {
  final String? id;
  final String name;
  final String brand;
  final String model;
  final String power;
  final int workingHours;
  final String warehouseId;
  final String farmId;
  final String? imageUrl;
  final bool isMotorized; // <--- NOVA FLAG AQUI

  MachineModel({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.power,
    required this.workingHours,
    required this.warehouseId,
    required this.farmId,
    this.imageUrl,
    this.isMotorized = true, // Por padrão, assumimos que tem motor
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'power': power,
      'workingHours': workingHours,
      'warehouseId': warehouseId,
      'farmId': farmId,
      'imageUrl': imageUrl,
      'isMotorized': isMotorized, // Salva no banco
    };
  }

  factory MachineModel.fromMap(Map<String, dynamic> map) {
    return MachineModel(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      power: map['power'] ?? '',
      workingHours: map['workingHours'] ?? 0,
      warehouseId: map['warehouseId'] ?? '',
      farmId: map['farmId'] ?? '',
      imageUrl: map['imageUrl'],
      isMotorized:
          map['isMotorized'] ??
          true, // Lê do banco (evita quebrar máquinas antigas)
    );
  }

  String toJson() => json.encode(toMap());

  factory MachineModel.fromJson(String source) =>
      MachineModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
