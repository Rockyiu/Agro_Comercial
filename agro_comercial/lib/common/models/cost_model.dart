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

  CostModel({
    this.id,
    required this.farmId,
    required this.type,
    required this.category,
    required this.value,
    required this.dateTimestamp,
    this.observation,
    this.calculationData,
  });

  // Função para identificar rapidamente se é um custo restrito ao Admin
  bool get isLabor => category.toLowerCase().contains('mão de obra');

  Map<String, dynamic> toMap() {
    return {
      'farmId': farmId,
      'type': type,
      'category': category,
      'value': value,
      'dateTimestamp': dateTimestamp,
      'observation': observation,
      'calculationData': calculationData,
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
    );
  }
}
