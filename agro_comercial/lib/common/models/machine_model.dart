import 'dart:convert';

import 'machine_cost_data.dart';

class MachineModel {
  final String? id;
  final String name;
  final String brand;
  final String model;
  final String power;
  final double workingHours; // Horímetro (aceita frações de hora)
  final String warehouseId;
  final String farmId;
  final bool isMotorized; // false = implemento sem motor/horímetro
  final MachineCostData? costData; // Dados do custo da hora-máquina

  MachineModel({
    this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.power,
    required this.workingHours,
    required this.warehouseId,
    required this.farmId,
    this.isMotorized = true, // Por padrão, assumimos que tem motor
    this.costData,
  });

  // "75" -> "75 cv"; quem digitou a unidade ("75 CV") fica como está
  String get powerLabel {
    final value = power.trim();
    if (value.isEmpty) return '-';
    return RegExp(r'[a-zA-Z]').hasMatch(value) ? value : "$value cv";
  }

  MachineModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? model,
    String? power,
    double? workingHours,
    String? warehouseId,
    String? farmId,
    bool? isMotorized,
    MachineCostData? costData,
  }) {
    return MachineModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      power: power ?? this.power,
      workingHours: workingHours ?? this.workingHours,
      warehouseId: warehouseId ?? this.warehouseId,
      farmId: farmId ?? this.farmId,
      isMotorized: isMotorized ?? this.isMotorized,
      costData: costData ?? this.costData,
    );
  }

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
      'isMotorized': isMotorized, // Salva no banco
      'costData': costData?.toMap(),
    };
  }

  factory MachineModel.fromMap(Map<String, dynamic> map) {
    return MachineModel(
      id: map['id'],
      name: map['name'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      power: map['power'] ?? '',
      workingHours: (map['workingHours'] as num?)?.toDouble() ?? 0,
      warehouseId: map['warehouseId'] ?? '',
      farmId: map['farmId'] ?? '',
      isMotorized:
          map['isMotorized'] ??
          true, // Lê do banco (evita quebrar máquinas antigas)
      costData: map['costData'] != null
          ? MachineCostData.fromMap(Map<String, dynamic>.from(map['costData']))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory MachineModel.fromJson(String source) =>
      MachineModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
