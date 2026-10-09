import 'dart:math';

import 'package:agro_comercial/common/utils/parsers.dart';

// Talhão (área de plantio) de uma fazenda.
//
// O [id] é a identidade do talhão: não muda quando ele é renomeado, e os
// lançamentos (operações, custos, colheitas) guardam esse id junto do nome.
// Os nomes anteriores ficam em [formerNames] para que lançamentos antigos,
// gravados só com o nome, continuem ligados ao talhão depois de renomeado.
class PlotModel {
  final String id;
  final String name;
  final double area; // na unidade de área da fazenda
  final String crop;
  final List<String> formerNames;

  const PlotModel({
    required this.id,
    required this.name,
    required this.area,
    required this.crop,
    this.formerNames = const [],
  });

  // Novo talhão (ainda não gravado)
  factory PlotModel.create({
    required String name,
    required double area,
    required String crop,
  }) {
    return PlotModel(id: newId(), name: name, area: area, crop: crop);
  }

  // Talhões gravados antes de existir o id recebem um id derivado do nome.
  // Ele passa a ser gravado na próxima vez que a fazenda for salva, então os
  // lançamentos feitos até lá continuam apontando para o mesmo talhão.
  static String legacyId(String name) => 'legacy:${normalize(name)}';

  static String newId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String normalize(String name) => name.trim().toLowerCase();

  // Nome atual ou algum nome anterior (sem diferenciar maiúsculas)
  bool answersTo(String name) {
    final target = normalize(name);
    return normalize(this.name) == target ||
        formerNames.any((former) => normalize(former) == target);
  }

  // Altera os dados mantendo o id; o nome antigo vai para o histórico
  PlotModel update({
    required String name,
    required double area,
    required String crop,
  }) {
    final renamed = normalize(name) != normalize(this.name);
    return PlotModel(
      id: id,
      name: name,
      area: area,
      crop: crop,
      formerNames: renamed
          ? {
              ...formerNames.where((n) => normalize(n) != normalize(name)),
              this.name,
            }.toList()
          : formerNames,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'area': area,
      'crop': crop,
      if (formerNames.isNotEmpty) 'formerNames': formerNames,
    };
  }

  factory PlotModel.fromMap(Map<String, dynamic> map) {
    final name = map['name']?.toString().trim() ?? '';
    final rawArea = map['area'];
    final id = map['id']?.toString() ?? '';
    return PlotModel(
      id: id.isEmpty ? legacyId(name) : id,
      name: name,
      area: rawArea is num
          ? rawArea.toDouble()
          : Parsers.decimal(rawArea?.toString() ?? '') ?? 0,
      crop: map['crop']?.toString() ?? '',
      formerNames: [
        for (final former in map['formerNames'] as List<dynamic>? ?? const [])
          former.toString(),
      ],
    );
  }
}
