class FieldOperationModel {
  final String? id;
  final String type; // 'Vistoria' ou 'Aplicação'
  final String plotName; // Nome/Número do Talhão
  final int dateTimestamp;
  final String farmId;

  final String? condition;
  final String? observations;

  final String? productId;
  final String? productName;
  final double? dosage;
  final String? dosageUnit;

  final String? machineId;
  final String? machineName;
  final double? machineHours; // ADICIONADO: Para podermos estornar depois

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
    this.machineHours, // ADICIONADO
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type, 'plotName': plotName, 'dateTimestamp': dateTimestamp,
      'farmId': farmId, 'condition': condition, 'observations': observations,
      'productId': productId, 'productName': productName, 'dosage': dosage,
      'dosageUnit': dosageUnit,
      'machineId': machineId,
      'machineName': machineName,
      'machineHours': machineHours, // ADICIONADO
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
      machineHours: (map['machineHours'] as num?)?.toDouble(), // ADICIONADO
    );
  }
}
