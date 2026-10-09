import 'dart:convert';

import 'package:agro_comercial/common/models/plot_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';

class FarmModel {
  final String? id;
  final String name;
  final String cadPro;
  final String address;
  final String totalArea; // Atualizado de 'area' para 'totalArea'
  final List<PlotModel> plots; // Talhões (gravados em 'plantedFields')
  final String? ownerId;
  // Unidade da área total e dos talhões: 'ha' (hectare) ou 'alq' (alqueire)
  final String areaUnit;

  FarmModel({
    this.id,
    required this.name,
    required this.cadPro,
    required this.address,
    required this.totalArea,
    required this.plots,
    this.ownerId,
    this.areaUnit = AreaUnits.hectare,
  });

  // Ex: "43 alq" ou "104 ha"
  String get totalAreaLabel {
    final area = totalArea.trim();
    return area.isEmpty ? '-' : "$area ${AreaUnits.shortLabel(areaUnit)}";
  }

  // Nomes dos talhões (usados nos seletores de talhão dos formulários)
  List<String> get plotNames => plots.map((plot) => plot.name).toList();

  // Talhão de um lançamento: pelo id e, nos lançamentos antigos (sem id),
  // pelo nome atual ou por um nome que o talhão já teve
  PlotModel? findPlot({String? id, String? name}) {
    if (id != null && id.isNotEmpty) {
      final byId = plots.where((p) => p.id == id).firstOrNull;
      if (byId != null) return byId;
    }
    if (name == null || name.trim().isEmpty) return null;
    final normalized = PlotModel.normalize(name);
    return plots
            .where((p) => PlotModel.normalize(p.name) == normalized)
            .firstOrNull ??
        plots.where((p) => p.answersTo(name)).firstOrNull;
  }

  // Nome atual do talhão do lançamento (acompanha renomeações). Se o talhão
  // não existe mais, devolve o nome gravado no lançamento.
  String? currentPlotName({String? id, String? name}) =>
      findPlot(id: id, name: name)?.name ?? name;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'cadPro': cadPro,
      'address': address,
      'totalArea': totalArea,
      'plantedFields': plots.map((plot) => plot.toMap()).toList(),
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
      // Fazendas antigas podem não ter talhões
      plots: _plotsFromList(map['plantedFields'] as List<dynamic>?),
      ownerId: map['ownerId'] != null ? map['ownerId'] as String : null,
      areaUnit: map['areaUnit'] as String? ?? AreaUnits.hectare,
    );
  }

  // Talhões antigos com o mesmo nome receberiam o mesmo id derivado do nome
  static List<PlotModel> _plotsFromList(List<dynamic>? list) {
    final usedIds = <String>{};
    final plots = <PlotModel>[];
    for (final item in list ?? const []) {
      var plot = PlotModel.fromMap(Map<String, dynamic>.from(item as Map));
      if (!usedIds.add(plot.id)) {
        var suffix = 2;
        while (!usedIds.add('${plot.id}-$suffix')) {
          suffix++;
        }
        plot = PlotModel(
          id: '${plot.id}-$suffix',
          name: plot.name,
          area: plot.area,
          crop: plot.crop,
          formerNames: plot.formerNames,
        );
      }
      plots.add(plot);
    }
    return plots;
  }

  String toJson() => json.encode(toMap());

  factory FarmModel.fromJson(String source) =>
      FarmModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
