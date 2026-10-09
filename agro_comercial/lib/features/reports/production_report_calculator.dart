import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/plot_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/unit_converter.dart';

import 'production_report.dart';

// Dados de uma fazenda usados no relatório (como vieram do banco)
class FarmReportInput {
  final FarmModel farm;
  final List<OperationModel> operations;
  final List<FieldOperationModel> fieldOperations;
  final List<CostModel> costs;
  final List<HarvestModel> harvests;
  final List<MachineModel> machines;
  final List<ProductModel> products;

  const FarmReportInput({
    required this.farm,
    this.operations = const [],
    this.fieldOperations = const [],
    this.costs = const [],
    this.harvests = const [],
    this.machines = const [],
    this.products = const [],
  });
}

// Monta o relatório de custo de produção:
//
// - Insumos: quantidade aplicada (convertida para a unidade do estoque) x preço
//   do produto no dia do lançamento (ou o preço atual, em lançamentos antigos)
// - Máquinas: horas trabalhadas x (depreciação + manutenção por hora) e
//   horas x consumo x preço do diesel
// - Juros e seguro das máquinas: valor anual proporcional ao período,
//   rateado entre os talhões pela área
// - Custos: valor lançado, no grupo de despesa da categoria
// - Produção: quantidade colhida e receita
//
// O que foi lançado sem talhão (ou num talhão que não existe mais) é rateado
// entre os talhões da fazenda proporcionalmente à área.
class ProductionReportCalculator {
  ProductionReportCalculator._();

  static ProductionReport build({
    required List<FarmReportInput> farms,
    required ReportPeriod period,
    required double dieselPrice,
  }) {
    final warnings = ReportWarnings();
    final plots = <PlotReport>[];
    final machineRows = <MachineCostRow>[];

    for (final input in farms) {
      final builder = _FarmReportBuilder(input, period, dieselPrice, warnings)
        ..build();
      plots.addAll(builder.plots);
      machineRows.addAll(builder.machineRows);
    }

    return ProductionReport(
      period: period,
      dieselPrice: dieselPrice,
      farms: [for (final input in farms) input.farm],
      plots: plots,
      machineRows: machineRows,
      warnings: warnings,
    );
  }
}

class _FarmReportBuilder {
  final FarmReportInput input;
  final ReportPeriod period;
  final double dieselPrice;
  final ReportWarnings warnings;

  // Talhões do relatório, pelo id do talhão na fazenda
  late final Map<String, PlotReport> _plotsById = {
    for (final plot in farm.plots)
      if (plot.name.isNotEmpty) plot.id: _plotReport(plot),
  };
  // Fazenda sem talhões: tudo vai para a área total
  late final List<PlotReport> plots = _plotsById.isEmpty
      ? [_totalAreaReport()]
      : _plotsById.values.toList();
  late final List<double> _weights = _areaWeights();
  late final Map<String, MachineModel> _machines = {
    for (final m in input.machines)
      if (m.id != null) m.id!: m,
  };
  late final Map<String, ProductModel> _products = {
    for (final p in input.products)
      if (p.id != null) p.id!: p,
  };
  final Map<String, double> _hoursByMachine = {};
  final List<MachineCostRow> machineRows = [];

  _FarmReportBuilder(this.input, this.period, this.dieselPrice, this.warnings);

  FarmModel get farm => input.farm;

  void build() {
    for (final op in input.operations) {
      if (period.contains(op.dateTimestamp)) _addOperation(op);
    }
    for (final op in input.fieldOperations) {
      if (!op.isInspection && period.contains(op.dateTimestamp)) {
        _addFieldOperation(op);
      }
    }
    for (final cost in input.costs) {
      if (period.contains(cost.dateTimestamp)) _addCost(cost);
    }
    for (final harvest in input.harvests) {
      if (period.contains(harvest.dateTimestamp)) _addHarvest(harvest);
    }
    _addMachineInterestAndInsurance();
    _buildMachineRows();
  }

  // --- Talhões e rateio ---

  PlotReport _plotReport(PlotModel plot) {
    if (plot.area <= 0) {
      warnings.plotsWithoutArea.add("${plot.name} (${farm.name})");
    }
    return PlotReport(
      farmId: farm.id ?? '',
      farmName: farm.name,
      plotName: plot.name,
      crop: plot.crop,
      areaHa: AreaUnits.toHectares(plot.area, farm.areaUnit),
    );
  }

  PlotReport _totalAreaReport() => PlotReport(
    farmId: farm.id ?? '',
    farmName: farm.name,
    plotName: 'Área total',
    crop: '',
    areaHa: AreaUnits.toHectares(
      Parsers.decimal(farm.totalArea) ?? 0,
      farm.areaUnit,
    ),
  );

  // Participação de cada talhão no rateio (pela área; sem áreas, partes iguais)
  List<double> _areaWeights() {
    final totalArea = plots.fold(0.0, (sum, p) => sum + p.areaHa);
    if (totalArea <= 0) return [for (final _ in plots) 1 / plots.length];
    return [for (final p in plots) p.areaHa / totalArea];
  }

  // Talhão do lançamento, ou null quando o valor deve ser rateado. Pelo id
  // do talhão; lançamentos antigos (sem id) pelo nome atual ou anterior.
  PlotReport? _resolvePlot(String? plotId, String? plotName) {
    final hasId = plotId?.isNotEmpty ?? false;
    final hasName = plotName?.trim().isNotEmpty ?? false;
    if (!hasId && !hasName) {
      warnings.sharedRecords++;
      return null;
    }
    final plot = _plotsById[farm.findPlot(id: plotId, name: plotName)?.id];
    if (plot == null) warnings.unmatchedPlotRecords++;
    return plot;
  }

  // Aplica o lançamento no talhão (parte = 1) ou em todos, pela área
  void _allocate(
    PlotReport? target,
    void Function(PlotReport plot, double share, bool isShared) apply,
  ) {
    if (target != null) {
      apply(target, 1, false);
      return;
    }
    for (var i = 0; i < plots.length; i++) {
      if (_weights[i] > 0) apply(plots[i], _weights[i], true);
    }
  }

  // --- Lançamentos ---

  void _addOperation(OperationModel op) {
    final hasCost =
        (op.usedProducts && op.appliedProducts.isNotEmpty) ||
        (op.usedMachine && (op.machineHours ?? 0) > 0);
    if (!hasCost) return;
    final target = _resolvePlot(op.plotId, op.plotName);

    if (op.usedProducts) {
      for (final applied in op.appliedProducts) {
        _addInput(
          target,
          operation: op.title,
          date: op.dateTimestamp,
          productId: applied['productId'] as String?,
          productName: applied['productName'] as String?,
          dosage: (applied['dosage'] as num?)?.toDouble(),
          dosageUnit: applied['dosageUnit'] as String?,
          snapshotPrice: (applied['unitPrice'] as num?)?.toDouble(),
          snapshotUnit: applied['productUnit'] as String?,
        );
      }
    }

    if (op.usedMachine) {
      final hours = op.machineHours ?? 0;
      _addMachineUsage(
        target,
        operation: op.title,
        date: op.dateTimestamp,
        machineId: op.machineId,
        machineName: op.machineName,
        hours: hours,
      );
      // O implemento trabalha as mesmas horas do trator
      if (op.implementId != null) {
        _addMachineUsage(
          target,
          operation: op.title,
          date: op.dateTimestamp,
          machineId: op.implementId,
          machineName: op.implementName,
          hours: hours,
        );
      }
    }
  }

  void _addFieldOperation(FieldOperationModel op) {
    final hasCost = (op.dosage ?? 0) > 0 || (op.machineHours ?? 0) > 0;
    if (!hasCost) return;
    final target = _resolvePlot(op.plotId, op.plotName);
    final operation = op.type;

    _addInput(
      target,
      operation: operation,
      date: op.dateTimestamp,
      productId: op.productId,
      productName: op.productName,
      dosage: op.dosage,
      dosageUnit: op.dosageUnit,
      snapshotPrice: op.unitPrice,
      snapshotUnit: op.productUnit,
    );
    _addMachineUsage(
      target,
      operation: operation,
      date: op.dateTimestamp,
      machineId: op.machineId,
      machineName: op.machineName,
      hours: op.machineHours ?? 0,
    );
  }

  void _addInput(
    PlotReport? target, {
    required String operation,
    required int date,
    required String? productId,
    required String? productName,
    required double? dosage,
    required String? dosageUnit,
    required double? snapshotPrice,
    required String? snapshotUnit,
  }) {
    if (dosage == null || dosage <= 0) return;
    final product = _products[productId];
    final name = productName ?? product?.name ?? 'Produto';
    final fromUnit = dosageUnit ?? product?.unit ?? '';

    // O preço gravado no lançamento vale para a unidade gravada junto com ele
    final double? price;
    final String unit;
    if (snapshotPrice != null) {
      price = snapshotPrice;
      unit = snapshotUnit ?? product?.unit ?? fromUnit;
    } else {
      price = product?.unitPrice;
      unit = product?.unit ?? fromUnit;
    }
    if (price == null) warnings.productsWithoutPrice.add(name);

    final quantity = UnitConverter.convert(dosage, fromUnit, unit);
    final total = quantity * (price ?? 0);

    _allocate(target, (plot, share, isShared) {
      plot.inputs.add(
        InputUsageLine(
          operation: operation,
          date: date,
          productName: name,
          formulation: product?.formulation ?? '',
          quantity: quantity * share,
          unit: unit,
          unitPrice: price,
          total: total * share,
          isShared: isShared,
        ),
      );
    });
  }

  void _addMachineUsage(
    PlotReport? target, {
    required String operation,
    required int date,
    required String? machineId,
    required String? machineName,
    required double hours,
  }) {
    if (machineId == null || hours <= 0) return;
    final machine = _machines[machineId];
    final name = machineName ?? machine?.name ?? 'Máquina';
    final data = machine?.costData;

    _hoursByMachine[machineId] = (_hoursByMachine[machineId] ?? 0) + hours;
    if (!(data?.isComplete ?? false)) {
      warnings.machinesWithoutCostData.add(name);
    }
    if ((data?.fuelConsumption ?? 0) > 0 && dieselPrice <= 0) {
      warnings.dieselPriceMissing = true;
    }

    final costPerHour = data?.fixedCostPerHour ?? 0;
    final fuelPerHour = data?.fuelCostPerHour(dieselPrice) ?? 0;

    _allocate(target, (plot, share, isShared) {
      final plotHours = hours * share;
      plot.machines.add(
        MachineUsageLine(
          operation: operation,
          date: date,
          machineName: name,
          hours: plotHours,
          costPerHour: costPerHour,
          fixedCost: plotHours * costPerHour,
          fuelCost: plotHours * fuelPerHour,
          isShared: isShared,
        ),
      );
    });
  }

  void _addCost(CostModel cost) {
    // Valores por hora de máquina não são despesas: ficam de fora da soma
    if (CostCategories.isHourlyRate(cost.category)) {
      warnings.ignoredHourlyCosts++;
      return;
    }
    final target = _resolvePlot(cost.plotId, cost.plotName);
    final observation = cost.observation?.trim() ?? '';
    final description = observation.isEmpty
        ? cost.category
        : "${cost.category} - $observation";

    _allocate(target, (plot, share, isShared) {
      plot.expenses.add(
        ExpenseLine(
          group: CostCategories.groupOf(cost.category),
          description: description,
          date: cost.dateTimestamp,
          value: cost.value * share,
          isShared: isShared,
        ),
      );
    });
  }

  void _addHarvest(HarvestModel harvest) {
    final target = _resolvePlot(harvest.plotId, harvest.plotName);
    _allocate(target, (plot, share, isShared) {
      plot.production.add(
        ProductionLine(
          date: harvest.dateTimestamp,
          quantity: harvest.quantity * share,
          unit: harvest.unit,
          unitPrice: harvest.unitPrice,
          revenue: harvest.revenue * share,
          isShared: isShared,
        ),
      );
    });
  }

  // Juros de oportunidade e seguro são custos fixos anuais das máquinas:
  // entram proporcionalmente aos dias do período, rateados pela área
  void _addMachineInterestAndInsurance() {
    final annual = input.machines.fold(
      0.0,
      (sum, m) => sum + (m.costData?.annualInterestAndInsurance ?? 0),
    );
    final value = annual * period.days / 365;
    if (value <= 0) return;

    _allocate(null, (plot, share, isShared) {
      plot.expenses.add(
        ExpenseLine(
          group: ExpenseGroup.juros,
          description: 'Juros e seguro das máquinas (rateio por área)',
          date: null,
          value: value * share,
          isShared: true,
        ),
      );
    });
  }

  void _buildMachineRows() {
    for (final machine in input.machines) {
      machineRows.add(
        MachineCostRow(
          farmName: farm.name,
          machine: machine,
          hoursInPeriod: _hoursByMachine[machine.id] ?? 0,
          dieselPrice: dieselPrice,
        ),
      );
    }
  }
}
