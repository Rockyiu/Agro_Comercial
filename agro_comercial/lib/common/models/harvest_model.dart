// Produção colhida em um talhão (quantidade, preço de venda e receita)
class HarvestModel {
  final String? id;
  final String farmId;
  final String plotName; // Talhão colhido
  final String?
  plotId; // Id do talhão (PlotModel.id); vazio em lançamentos antigos
  final String crop; // Cultura do talhão no momento da colheita
  final int dateTimestamp;
  final double quantity;
  final String unit; // Ver HarvestUnits
  final double unitPrice; // Preço de venda por unidade
  final String? observation;
  final String? createdBy;

  HarvestModel({
    this.id,
    required this.farmId,
    required this.plotName,
    this.plotId,
    required this.crop,
    required this.dateTimestamp,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.observation,
    this.createdBy,
  });

  double get revenue => quantity * unitPrice;

  HarvestModel copyWith({
    String? id,
    String? farmId,
    String? plotName,
    String? plotId,
    String? crop,
    int? dateTimestamp,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? observation,
    String? createdBy,
  }) {
    return HarvestModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      plotName: plotName ?? this.plotName,
      plotId: plotId ?? this.plotId,
      crop: crop ?? this.crop,
      dateTimestamp: dateTimestamp ?? this.dateTimestamp,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      observation: observation ?? this.observation,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'farmId': farmId,
      'plotName': plotName,
      'plotId': plotId,
      'crop': crop,
      'dateTimestamp': dateTimestamp,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'observation': observation,
      'createdBy': createdBy,
    };
  }

  factory HarvestModel.fromMap(Map<String, dynamic> map) {
    return HarvestModel(
      id: map['id'],
      farmId: map['farmId'] ?? '',
      plotName: map['plotName'] ?? '',
      plotId: map['plotId'],
      crop: map['crop'] ?? '',
      dateTimestamp:
          map['dateTimestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] ?? HarvestUnits.bag,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      observation: map['observation'],
      createdBy: map['createdBy'],
    );
  }
}

// Unidades da produção colhida
class HarvestUnits {
  HarvestUnits._();

  static const String bag = 'sc'; // Saca de 60 kg
  static const String kilogram = 'kg';
  static const String ton = 't';
  static const String box = 'cx';
  static const String unit = 'un';

  static const Map<String, String> labels = {
    bag: 'Saca (60 kg)',
    kilogram: 'Quilo (kg)',
    ton: 'Tonelada (t)',
    box: 'Caixa (cx)',
    unit: 'Unidade (un)',
  };

  // Peso em kg das unidades de massa (as demais não são convertidas)
  static const Map<String, double> _kilograms = {
    bag: 60,
    kilogram: 1,
    ton: 1000,
  };

  // Converte entre unidades de massa. Retorna null se não houver conversão
  // (ex: caixas para sacas).
  static double? convert(double quantity, String from, String to) {
    if (from == to) return quantity;
    final fromKg = _kilograms[from];
    final toKg = _kilograms[to];
    if (fromKg == null || toKg == null) return null;
    return quantity * fromKg / toKg;
  }
}
