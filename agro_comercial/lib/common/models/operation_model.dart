class OperationModel {
  final String? id;
  final String title; // Nome da operação selecionada no dropdown
  final String description;
  final String farmId;
  final int dateTimestamp;
  final String? createdBy; // UID de quem registrou a operação
  // Talhão onde a operação foi feita. Vazio = fazenda inteira (nos relatórios
  // o custo é rateado entre os talhões pela área)
  final String? plotName;
  final String?
  plotId; // Id do talhão (PlotModel.id); vazio em lançamentos antigos

  // Maquinário utilizado
  final bool usedMachine;
  final String? machineId;
  final String? machineName;
  final double? machineHours;
  // Implemento acoplado ao trator (trabalha as mesmas horas da máquina)
  final String? implementId;
  final String? implementName;

  // Produtos utilizados (Lista de 1 a 10 produtos stocados).
  // Cada item: productId, productName, dosage, dosageUnit e, desde os
  // relatórios de custo, unitPrice e productUnit (preço no dia do lançamento)
  final bool usedProducts;
  final List<Map<String, dynamic>> appliedProducts;

  OperationModel({
    this.id,
    required this.title,
    required this.description,
    required this.farmId,
    required this.dateTimestamp,
    this.createdBy,
    this.plotName,
    this.plotId,
    required this.usedMachine,
    this.machineId,
    this.machineName,
    this.machineHours,
    this.implementId,
    this.implementName,
    required this.usedProducts,
    required this.appliedProducts,
  });

  OperationModel copyWith({
    String? id,
    String? title,
    String? description,
    String? farmId,
    int? dateTimestamp,
    String? createdBy,
    String? plotName,
    String? plotId,
    bool? usedMachine,
    String? machineId,
    String? machineName,
    double? machineHours,
    String? implementId,
    String? implementName,
    bool? usedProducts,
    List<Map<String, dynamic>>? appliedProducts,
  }) {
    return OperationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      farmId: farmId ?? this.farmId,
      dateTimestamp: dateTimestamp ?? this.dateTimestamp,
      createdBy: createdBy ?? this.createdBy,
      plotName: plotName ?? this.plotName,
      plotId: plotId ?? this.plotId,
      usedMachine: usedMachine ?? this.usedMachine,
      machineId: machineId ?? this.machineId,
      machineName: machineName ?? this.machineName,
      machineHours: machineHours ?? this.machineHours,
      implementId: implementId ?? this.implementId,
      implementName: implementName ?? this.implementName,
      usedProducts: usedProducts ?? this.usedProducts,
      appliedProducts: appliedProducts ?? this.appliedProducts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'farmId': farmId,
      'dateTimestamp': dateTimestamp,
      'createdBy': createdBy,
      'plotName': plotName,
      'plotId': plotId,
      'usedMachine': usedMachine,
      'machineId': machineId,
      'machineName': machineName,
      'machineHours': machineHours,
      'implementId': implementId,
      'implementName': implementName,
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
      createdBy: map['createdBy'],
      plotName: map['plotName'],
      plotId: map['plotId'],
      usedMachine: map['usedMachine'] ?? false,
      machineId: map['machineId'],
      machineName: map['machineName'],
      machineHours: (map['machineHours'] as num?)?.toDouble(),
      implementId: map['implementId'],
      implementName: map['implementName'],
      usedProducts: map['usedProducts'] ?? false,
      appliedProducts: List<Map<String, dynamic>>.from(
        map['appliedProducts'] ?? [],
      ),
    );
  }
}
