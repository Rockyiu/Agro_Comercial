import 'dart:convert';

class WarehouseModel {
  final String? id;
  final String name;
  final String farmId; // ID da fazenda dona deste armazém

  WarehouseModel({this.id, required this.name, required this.farmId});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'name': name, 'farmId': farmId};
  }

  factory WarehouseModel.fromMap(Map<String, dynamic> map) {
    return WarehouseModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] as String,
      farmId: map['farmId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WarehouseModel.fromJson(String source) =>
      WarehouseModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
