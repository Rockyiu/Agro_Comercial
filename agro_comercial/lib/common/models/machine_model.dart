import 'dart:convert';

class MachineModel {
  final String? id;
  final String name; // Ex: Trator 1, Colhedora
  final String model;
  final String brand; // Marca
  final String power; // Potência
  final int workingHours; // Horas trabalhadas
  final String? imageUrl; // Link da foto no Firebase Storage
  final String warehouseId; // Em qual armazém ela está
  final String farmId; // De qual fazenda ela é

  MachineModel({
    this.id,
    required this.name,
    required this.model,
    required this.brand,
    required this.power,
    required this.workingHours,
    this.imageUrl,
    required this.warehouseId,
    required this.farmId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'model': model,
      'brand': brand,
      'power': power,
      'workingHours': workingHours,
      'imageUrl': imageUrl,
      'warehouseId': warehouseId,
      'farmId': farmId,
    };
  }

  factory MachineModel.fromMap(Map<String, dynamic> map) {
    return MachineModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] as String,
      model: map['model'] as String,
      brand: map['brand'] as String,
      power: map['power'] as String,
      workingHours: map['workingHours'] as int,
      imageUrl: map['imageUrl'] != null ? map['imageUrl'] as String : null,
      warehouseId: map['warehouseId'] as String,
      farmId: map['farmId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory MachineModel.fromJson(String source) =>
      MachineModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
