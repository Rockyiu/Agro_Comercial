import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/utils/formatters.dart';

// Período do relatório (datas inclusivas)
class ReportPeriod {
  final DateTime start;
  final DateTime end;

  ReportPeriod(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  // Safra: 1º de julho de [startYear] a 30 de junho do ano seguinte
  factory ReportPeriod.cropYear(int startYear) =>
      ReportPeriod(DateTime(startYear, 7, 1), DateTime(startYear + 1, 6, 30));

  factory ReportPeriod.currentCropYear([DateTime? today]) {
    final now = today ?? DateTime.now();
    return ReportPeriod.cropYear(now.month >= 7 ? now.year : now.year - 1);
  }

  factory ReportPeriod.calendarYear(int year) =>
      ReportPeriod(DateTime(year, 1, 1), DateTime(year, 12, 31));

  int get days => end.difference(start).inDays + 1;

  bool contains(int millisecondsSinceEpoch) {
    final date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return !date.isBefore(start) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  String get label =>
      "${Formatters.date(start.millisecondsSinceEpoch)} a "
      "${Formatters.date(end.millisecondsSinceEpoch)}";
}

// Unidade de área em que o relatório é exibido (os cálculos são em hectares)
class AreaDisplay {
  final String unit; // AreaUnits.hectare ou AreaUnits.alqueire

  const AreaDisplay(this.unit);

  String get label => AreaUnits.shortLabel(unit);

  double area(double hectares) => AreaUnits.fromHectares(hectares, unit);

  // Valor por hectare convertido para valor por unidade exibida
  double perArea(double perHectare) => unit == AreaUnits.alqueire
      ? perHectare * AreaUnits.hectaresPerAlqueire
      : perHectare;
}

// Quantidades produzidas, somando unidades de massa convertíveis entre si
// (sacas, kg e t). Unidades diferentes (ex: caixas) ficam separadas.
class ProductionQuantities {
  final Map<String, double> _byUnit = {};

  void add(double quantity, String unit) {
    for (final key in _byUnit.keys) {
      final converted = HarvestUnits.convert(quantity, unit, key);
      if (converted != null) {
        _byUnit[key] = _byUnit[key]! + converted;
        return;
      }
    }
    _byUnit[unit] = quantity;
  }

  void addAll(ProductionQuantities other) =>
      other._byUnit.forEach((unit, quantity) => add(quantity, unit));

  bool get isEmpty => _byUnit.isEmpty;

  // Produtividade e custo por unidade só existem com uma única unidade
  bool get isSingleUnit => _byUnit.length == 1;

  String? get unit => isSingleUnit ? _byUnit.keys.first : null;

  double get quantity => isSingleUnit ? _byUnit.values.first : 0;

  String format() {
    if (_byUnit.isEmpty) return '-';
    return _byUnit.entries
        .map((e) => "${Formatters.decimal(e.value)} ${e.key}")
        .join(' + ');
  }
}

// Totais de custo, produção e receita de um talhão, propriedade, cultura ou
// do conjunto todo
class CostSummary {
  final String name;
  final String subtitle;
  double areaHa = 0;
  double revenue = 0;
  final Map<ExpenseGroup, double> costByGroup = {};
  final ProductionQuantities production = ProductionQuantities();

  CostSummary(this.name, {this.subtitle = ''});

  void addCost(ExpenseGroup group, double value) {
    if (value == 0) return;
    costByGroup[group] = (costByGroup[group] ?? 0) + value;
  }

  void absorb(CostSummary other) {
    areaHa += other.areaHa;
    revenue += other.revenue;
    other.costByGroup.forEach(addCost);
    production.addAll(other.production);
  }

  double get totalCost => costByGroup.values.fold(0.0, (sum, v) => sum + v);

  double get margin => revenue - totalCost;

  double _perHa(double value) => areaHa > 0 ? value / areaHa : 0;

  double get costPerHa => _perHa(totalCost);

  double get revenuePerHa => _perHa(revenue);

  double get marginPerHa => _perHa(margin);

  // Margem sobre a receita (%)
  double? get marginPercent => revenue > 0 ? margin / revenue * 100 : null;

  double? get productivityPerHa => production.isSingleUnit && areaHa > 0
      ? production.quantity / areaHa
      : null;

  double? get costPerUnit => production.isSingleUnit && production.quantity > 0
      ? totalCost / production.quantity
      : null;

  double? get averagePrice => production.isSingleUnit && production.quantity > 0
      ? revenue / production.quantity
      : null;

  // Quantas unidades (ex: sacas) por hectare pagam o custo
  double? get breakEvenPerHa {
    final price = averagePrice;
    if (price == null || price <= 0) return null;
    return costPerHa / price;
  }

  // Grupos de despesa do maior para o menor valor
  List<MapEntry<ExpenseGroup, double>> get sortedGroups =>
      costByGroup.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

// Insumo aplicado no talhão (controle físico)
class InputUsageLine {
  final String operation; // Operação / momento da aplicação
  final int date;
  final String productName;
  final String formulation;
  final double quantity; // Na unidade do estoque do produto
  final String unit;
  final double? unitPrice;
  final double total;
  final bool isShared; // Lançado sem talhão e rateado pela área

  const InputUsageLine({
    required this.operation,
    required this.date,
    required this.productName,
    required this.formulation,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.total,
    required this.isShared,
  });
}

// Horas de máquina trabalhadas no talhão
class MachineUsageLine {
  final String operation;
  final int date;
  final String machineName;
  final double hours;
  final double costPerHour; // Depreciação + manutenção
  final double fixedCost; // horas x custo/hora
  final double fuelCost; // horas x consumo x preço do diesel
  final bool isShared;

  const MachineUsageLine({
    required this.operation,
    required this.date,
    required this.machineName,
    required this.hours,
    required this.costPerHour,
    required this.fixedCost,
    required this.fuelCost,
    required this.isShared,
  });
}

// Despesa lançada em Custos (ou calculada, como juros e seguro das máquinas)
class ExpenseLine {
  final ExpenseGroup group;
  final String description;
  final int? date;
  final double value;
  final bool isShared;

  const ExpenseLine({
    required this.group,
    required this.description,
    required this.date,
    required this.value,
    required this.isShared,
  });
}

class ProductionLine {
  final int date;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double revenue;
  final bool isShared;

  const ProductionLine({
    required this.date,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.revenue,
    required this.isShared,
  });
}

// Tudo o que aconteceu em um talhão no período
class PlotReport {
  final String farmId;
  final String farmName;
  final String plotName;
  final String crop;
  final double areaHa;

  final List<InputUsageLine> inputs = [];
  final List<MachineUsageLine> machines = [];
  final List<ExpenseLine> expenses = [];
  final List<ProductionLine> production = [];

  PlotReport({
    required this.farmId,
    required this.farmName,
    required this.plotName,
    required this.crop,
    required this.areaHa,
  });

  // Calculado na primeira leitura (depois de todas as linhas adicionadas)
  late final CostSummary summary = _buildSummary();

  CostSummary _buildSummary() {
    final summary = CostSummary(plotName, subtitle: farmName)..areaHa = areaHa;
    for (final line in inputs) {
      summary.addCost(ExpenseGroup.insumos, line.total);
    }
    for (final line in machines) {
      summary.addCost(ExpenseGroup.maquinas, line.fixedCost);
      summary.addCost(ExpenseGroup.combustivel, line.fuelCost);
    }
    for (final line in expenses) {
      summary.addCost(line.group, line.value);
    }
    for (final line in production) {
      summary.revenue += line.revenue;
      summary.production.add(line.quantity, line.unit);
    }
    return summary;
  }
}

// Linha da tabela de custo da hora-máquina
class MachineCostRow {
  final String farmName;
  final MachineModel machine;
  final double hoursInPeriod;
  final double dieselPrice;

  const MachineCostRow({
    required this.farmName,
    required this.machine,
    required this.hoursInPeriod,
    required this.dieselPrice,
  });

  MachineCostData? get data => machine.costData;

  bool get hasCostData => data?.isComplete ?? false;

  double get fuelCostPerHour => data?.fuelCostPerHour(dieselPrice) ?? 0;

  double get totalCostPerHour => data?.totalCostPerHour(dieselPrice) ?? 0;

  double get costInPeriod => totalCostPerHour * hoursInPeriod;
}

// Dados faltando que deixam o relatório incompleto
class ReportWarnings {
  final Set<String> productsWithoutPrice = {};
  final Set<String> machinesWithoutCostData = {};
  final Set<String> plotsWithoutArea = {};
  bool dieselPriceMissing = false;
  int sharedRecords = 0; // Lançamentos sem talhão, rateados pela área
  int unmatchedPlotRecords = 0; // Talhão não existe mais na fazenda
  int ignoredHourlyCosts = 0; // Custos calculados por hora (não somados)

  List<String> get messages => [
    if (productsWithoutPrice.isNotEmpty)
      "Produtos sem preço (custo zerado): ${productsWithoutPrice.join(', ')}.",
    if (machinesWithoutCostData.isNotEmpty)
      "Máquinas sem custo da hora-máquina: ${machinesWithoutCostData.join(', ')}.",
    if (dieselPriceMissing)
      "Informe o preço do diesel para calcular o combustível das máquinas.",
    if (plotsWithoutArea.isNotEmpty)
      "Talhões sem área cadastrada: ${plotsWithoutArea.join(', ')}.",
    if (sharedRecords > 0)
      "$sharedRecords lançamento(s) sem talhão foram rateados pela área.",
    if (unmatchedPlotRecords > 0)
      "$unmatchedPlotRecords lançamento(s) de talhões que não existem mais "
          "na fazenda entraram no rateio.",
    if (ignoredHourlyCosts > 0)
      "$ignoredHourlyCosts custo(s) calculados por hora de máquina não foram "
          "somados (o custo das máquinas vem do cadastro de cada máquina).",
  ];
}

class ProductionReport {
  final ReportPeriod period;
  final double dieselPrice;
  final List<FarmModel> farms;
  final List<PlotReport> plots;
  final List<MachineCostRow> machineRows;
  final ReportWarnings warnings;

  ProductionReport({
    required this.period,
    required this.dieselPrice,
    required this.farms,
    required this.plots,
    required this.machineRows,
    required this.warnings,
  });

  late final CostSummary total = _combine(
    farms.length == 1 ? farms.first.name : 'Todas as propriedades',
    plots,
  );

  late final List<CostSummary> byFarm = [
    for (final farm in farms)
      _combine(farm.name, plots.where((p) => p.farmId == farm.id)),
  ];

  late final List<CostSummary> byCrop = _groupByCrop();

  bool get isEmpty =>
      total.totalCost == 0 && total.revenue == 0 && machineRows.isEmpty;

  CostSummary _combine(String name, Iterable<PlotReport> plots) {
    final summary = CostSummary(name);
    for (final plot in plots) {
      summary.absorb(plot.summary);
    }
    return summary;
  }

  List<CostSummary> _groupByCrop() {
    final groups = <String, List<PlotReport>>{};
    final names = <String, String>{};
    for (final plot in plots) {
      final name = plot.crop.trim().isEmpty ? 'Sem cultura' : plot.crop.trim();
      final key = name.toLowerCase();
      names.putIfAbsent(key, () => name);
      groups.putIfAbsent(key, () => []).add(plot);
    }
    return [
      for (final entry in groups.entries)
        _combine(names[entry.key]!, entry.value),
    ]..sort((a, b) => b.areaHa.compareTo(a.areaHa));
  }
}
