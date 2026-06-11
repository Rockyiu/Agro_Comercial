class OperationModel {
  final String? id;
  final String title; // Nome da operação selecionada no dropdown
  final String description;
  final String farmId;
  final int dateTimestamp;

  // Maquinário utilizado
  final bool usedMachine;
  final String? machineId;
  final String? machineName;
  final double? machineHours;

  // Produtos utilizados (Lista de 1 a 10 produtos stocados)
  final bool usedProducts;
  final List<Map<String, dynamic>> appliedProducts;

  OperationModel({
    this.id,
    required this.title,
    required this.description,
    required this.farmId,
    required this.dateTimestamp,
    required this.usedMachine,
    this.machineId,
    this.machineName,
    this.machineHours,
    required this.usedProducts,
    required this.appliedProducts,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'farmId': farmId,
      'dateTimestamp': dateTimestamp,
      'usedMachine': usedMachine,
      'machineId': machineId,
      'machineName': machineName,
      'machineHours': machineHours,
      'usedProducts': usedProducts,
      'appliedProducts': appliedProducts,
    };
  }

  factory OperationModel.fromMap(Map<String, dynamic> map) {
    return OperationModel(
      id: map['id'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      farmId: map['farmId'] ?? '',
      dateTimestamp:
          map['dateTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      usedMachine: map['usedMachine'] ?? false,
      machineId: map['machineId'],
      machineName: map['machineName'],
      machineHours: (map['machineHours'] as num?)?.toDouble(),
      usedProducts: map['usedProducts'] ?? false,
      appliedProducts: List<Map<String, dynamic>>.from(
        map['appliedProducts'] ?? [],
      ),
    );
  }
}
