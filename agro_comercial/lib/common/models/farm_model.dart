import 'dart:convert';

class FarmModel {
  final String? id;
  final String name;
  final String cadPro; // ADICIONADO: Inscrição Estadual
  final String address;
  final String area;
  final int numberOfPlots;
  final List<String> plotCrops;
  final String? ownerId;

  FarmModel({
    this.id,
    required this.name,
    required this.cadPro, // ADICIONADO
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
      'cadPro': cadPro, // ADICIONADO
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
      cadPro: map['cadPro'] != null
          ? map['cadPro'] as String
          : '', // ADICIONADO
      address: map['address'] as String,
      area: map['area'] as String,
      numberOfPlots: map['numberOfPlots'] as int,
      plotCrops: List<String>.from(map['plotCrops'] as List<dynamic>),
      ownerId: map['ownerId'] != null ? map['ownerId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FarmModel.fromJson(String source) =>
      FarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
