// Dados para o cálculo do custo da hora-máquina (planilha "custos da hora
// máquina"). Todos os percentuais são guardados como digitados (ex: 20 = 20%).
class MachineCostData {
  final double? acquisitionValue; // Valor original de aquisição (inventário)
  final int? acquisitionDate; // Data da aquisição (timestamp)
  final double? scrapPercent; // Valor de sucata, em % do valor inicial
  final double? usefulLifeHours; // Vida útil em horas
  final double? maintenancePercent; // Manutenção na vida útil, em % do V.I.
  final double? marketValue; // Valor atual de mercado do bem
  final double? insuranceRate; // Taxa de seguro (% ao ano)
  final double? interestRate; // Juros de oportunidade (% ao ano)
  final double? fuelConsumption; // Consumo de diesel (L/hora)
  // Bem já totalmente depreciado na contabilidade: depreciação/hora zerada
  final bool fullyDepreciated;

  const MachineCostData({
    this.acquisitionValue,
    this.acquisitionDate,
    this.scrapPercent,
    this.usefulLifeHours,
    this.maintenancePercent,
    this.marketValue,
    this.insuranceRate,
    this.interestRate,
    this.fuelConsumption,
    this.fullyDepreciated = false,
  });

  bool get _hasLife => (usefulLifeHours ?? 0) > 0;

  // Tem o mínimo para calcular depreciação e manutenção por hora
  bool get isComplete => (acquisitionValue ?? 0) > 0 && _hasLife;

  // Valor de sucata = valor inicial x % sucata
  double get scrapValue => (acquisitionValue ?? 0) * (scrapPercent ?? 0) / 100;

  // Depreciação = (preço de aquisição - valor de sucata) / vida útil (horas)
  double get depreciationPerHour {
    if (fullyDepreciated || !_hasLife) return 0;
    return ((acquisitionValue ?? 0) - scrapValue) / usefulLifeHours!;
  }

  // Manutenção = (% manutenção x valor de aquisição) / vida útil (horas)
  double get maintenancePerHour {
    if (!_hasLife) return 0;
    final factor = (maintenancePercent ?? 0) / 100;
    return factor * (acquisitionValue ?? 0) / usefulLifeHours!;
  }

  // Depreciação + manutenção: o valor usado no custo por talhão
  double get fixedCostPerHour => depreciationPerHour + maintenancePerHour;

  // Juros + seguro = valor atual do bem x (taxa de seguro + juros) por ano.
  // Sem o valor de mercado, usa o valor de aquisição.
  double get annualInterestAndInsurance {
    final value = marketValue ?? acquisitionValue ?? 0;
    return value * ((insuranceRate ?? 0) + (interestRate ?? 0)) / 100;
  }

  // Custo do diesel por hora trabalhada = consumo (L/h) x preço do litro
  double fuelCostPerHour(double dieselPrice) =>
      (fuelConsumption ?? 0) * dieselPrice;

  double totalCostPerHour(double dieselPrice) =>
      fixedCostPerHour + fuelCostPerHour(dieselPrice);

  Map<String, dynamic> toMap() {
    return {
      'acquisitionValue': acquisitionValue,
      'acquisitionDate': acquisitionDate,
      'scrapPercent': scrapPercent,
      'usefulLifeHours': usefulLifeHours,
      'maintenancePercent': maintenancePercent,
      'marketValue': marketValue,
      'insuranceRate': insuranceRate,
      'interestRate': interestRate,
      'fuelConsumption': fuelConsumption,
      'fullyDepreciated': fullyDepreciated,
    };
  }

  factory MachineCostData.fromMap(Map<String, dynamic> map) {
    double? number(String key) => (map[key] as num?)?.toDouble();
    return MachineCostData(
      acquisitionValue: number('acquisitionValue'),
      acquisitionDate: (map['acquisitionDate'] as num?)?.toInt(),
      scrapPercent: number('scrapPercent'),
      usefulLifeHours: number('usefulLifeHours'),
      maintenancePercent: number('maintenancePercent'),
      marketValue: number('marketValue'),
      insuranceRate: number('insuranceRate'),
      interestRate: number('interestRate'),
      fuelConsumption: number('fuelConsumption'),
      fullyDepreciated: map['fullyDepreciated'] ?? false,
    );
  }
}
