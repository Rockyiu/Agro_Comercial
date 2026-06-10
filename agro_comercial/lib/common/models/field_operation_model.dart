class FieldOperationModel {
  final String? id;
  final String type; // 'Vistoria' ou 'Aplicação'
  final String plotName; // Nome/Número do Talhão (Ex: Talhão 01)
  final int dateTimestamp; // Data da operação
  final String farmId;

  // Campos específicos para Vistoria
  final String? condition; // Excelente, Atenção, Crítico
  final String? observations;

  // Campos específicos para Aplicação
  final String? productId;
  final String? productName;
  final double? dosage;
  final String? dosageUnit; // L/ha, kg/ha, etc.
  final String? machineId;
  final String? machineName;

  FieldOperationModel({
    this.id,
    required this.type,
    required this.plotName,
    required this.dateTimestamp,
    required this.farmId,
    this.condition,
    this.observations,
    this.productId,
    this.productName,
    this.dosage,
    this.dosageUnit,
    this.machineId,
    this.machineName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'plotName': plotName,
      'dateTimestamp': dateTimestamp,
      'farmId': farmId,
      'condition': condition,
      'observations': observations,
      'productId': productId,
      'productName': productName,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'machineId': machineId,
      'machineName': machineName,
    };
  }

  factory FieldOperationModel.fromMap(Map<String, dynamic> map) {
    return FieldOperationModel(
      id: map['id'],
      type: map['type'] ?? 'Vistoria',
      plotName: map['plotName'] ?? '',
      dateTimestamp:
          map['dateTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      farmId: map['farmId'] ?? '',
      condition: map['condition'],
      observations: map['observations'],
      productId: map['productId'],
      productName: map['productName'],
      dosage: (map['dosage'] as num?)?.toDouble(),
      dosageUnit: map['dosageUnit'],
      machineId: map['machineId'],
      machineName: map['machineName'],
    );
  }
}
