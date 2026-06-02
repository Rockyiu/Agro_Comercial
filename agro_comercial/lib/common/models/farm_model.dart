import 'dart:convert';

class FarmModel {
  final String? id;
  final String name;
  final String address;
  final String area;
  final int numberOfPlots;
  final List<String> plotCrops;
  final String? ownerId; // ID do Administrador/Proprietário dono da fazenda

  FarmModel({
    this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.numberOfPlots,
    required this.plotCrops,
    this.ownerId,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'area': area,
      'numberOfPlots': numberOfPlots,
      'plotCrops': plotCrops,
      'ownerId': ownerId,
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] as String,
      address: map['address'] as String,
      area: map['area'] as String,
      numberOfPlots: map['numberOfPlots'] as int,
      // Converte a lista do Firebase de volta para uma Lista de Strings no Flutter
      plotCrops: List<String>.from(map['plotCrops'] as List<dynamic>),
      ownerId: map['ownerId'] != null ? map['ownerId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FarmModel.fromJson(String source) =>
      FarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
