class CostModel {
  final String? id;
  final String farmId;
  final String type; // 'Variável', 'Fixo', ou 'Outros'
  final String
  category; // Ex: 'Manutenção de Tratores', 'Insumos', 'Mão de Obra Temporária'
  final double value; // O valor final calculado ou digitado
  final int dateTimestamp;
  final String? observation;
  final Map<String, dynamic>?
  calculationData; // Guarda os valores usados na fórmula (Vi, Vs, Vm, etc)
  // Talhão ao qual o custo pertence. Vazio = fazenda inteira (nos relatórios
  // o valor é rateado entre os talhões pela área)
  final String? plotName;
  final String?
  plotId; // Id do talhão (PlotModel.id); vazio em lançamentos antigos

  CostModel({
    this.id,
    required this.farmId,
    required this.type,
    required this.category,
    required this.value,
    required this.dateTimestamp,
    this.observation,
    this.calculationData,
    this.plotName,
    this.plotId,
  });

  // Custos de mão de obra são restritos ao produtor (Admin).
  // As categorias são escritas "Mão-de-obra ...", por isso o hífen é ignorado.
  static bool isLaborCategory(String category) =>
      category.toLowerCase().replaceAll('-', ' ').contains('mão de obra');

  bool get isLabor => isLaborCategory(category);

  CostModel copyWith({
    String? id,
    String? farmId,
    String? type,
    String? category,
    double? value,
    int? dateTimestamp,
    String? observation,
    Map<String, dynamic>? calculationData,
    String? plotName,
    String? plotId,
  }) {
    return CostModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      type: type ?? this.type,
      category: category ?? this.category,
      value: value ?? this.value,
      dateTimestamp: dateTimestamp ?? this.dateTimestamp,
      observation: observation ?? this.observation,
      calculationData: calculationData ?? this.calculationData,
      plotName: plotName ?? this.plotName,
      plotId: plotId ?? this.plotId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmId': farmId,
      'type': type,
      'category': category,
      // Gravado para as regras do Firestore esconderem esses custos do
      // colaborador (a consulta dele filtra por laborCost == false)
      'laborCost': isLabor,
      'value': value,
      'dateTimestamp': dateTimestamp,
      'observation': observation,
      'calculationData': calculationData,
      'plotName': plotName,
      'plotId': plotId,
    };
  }

  factory CostModel.fromMap(Map<String, dynamic> map, String id) {
    return CostModel(
      id: id,
      farmId: map['farmId'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      value: (map['value'] ?? 0.0).toDouble(),
      dateTimestamp: map['dateTimestamp'] ?? 0,
      observation: map['observation'],
      calculationData: map['calculationData'] != null
          ? Map<String, dynamic>.from(map['calculationData'])
          : null,
      plotName: map['plotName'],
      plotId: map['plotId'],
    );
  }
}
