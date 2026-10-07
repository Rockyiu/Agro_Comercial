import 'dart:convert';

import 'package:agro_comercial/common/utils/area_units.dart';

class FarmModel {
  final String? id;
  final String name;
  final String cadPro;
  final String address;
  final String totalArea; // Atualizado de 'area' para 'totalArea'
  final List<Map<String, dynamic>>
  plantedFields; // ADICIONADO: Lista com os dados de cada talhão
  final String? ownerId;
  // Unidade da área total e dos talhões: 'ha' (hectare) ou 'alq' (alqueire)
  final String areaUnit;

  FarmModel({
    this.id,
    required this.name,
    required this.cadPro,
    required this.address,
    required this.totalArea,
    required this.plantedFields,
    this.ownerId,
    this.areaUnit = AreaUnits.hectare,
  });

  // Nomes dos talhões (usados nos seletores de talhão dos formulários)
  List<String> get plotNames =>
      plantedFields.map((field) => field['name'].toString()).toList();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cadPro': cadPro,
      'address': address,
      'totalArea': totalArea,
      'plantedFields': plantedFields, // Salva a lista de talhões
      'ownerId': ownerId,
      'areaUnit': areaUnit,
    };
  }

  factory FarmModel.fromMap(Map<String, dynamic> map) {
    return FarmModel(
      id: map['id'] != null ? map['id'] as String : null,
      name: map['name'] as String,
      cadPro: map['cadPro'] != null ? map['cadPro'] as String : '',
      address: map['address'] != null ? map['address'] as String : '',
      // Tenta pegar o 'totalArea', se não existir, tenta pegar o antigo 'area' para manter compatibilidade
      totalArea: map['totalArea'] != null
          ? map['totalArea'] as String
          : (map['area'] != null ? map['area'] as String : ''),
      // Mapeia a lista de talhões. Se for uma fazenda antiga sem isso, inicia uma lista vazia
      plantedFields: map['plantedFields'] != null
          ? List<Map<String, dynamic>>.from(
              map['plantedFields'] as List<dynamic>,
            )
          : [],
      ownerId: map['ownerId'] != null ? map['ownerId'] as String : null,
      areaUnit: map['areaUnit'] as String? ?? AreaUnits.hectare,
    );
  }

  String toJson() => json.encode(toMap());

  factory FarmModel.fromJson(String source) =>
      FarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
