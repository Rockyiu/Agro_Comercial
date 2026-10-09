import 'package:flutter_test/flutter_test.dart';

import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/plot_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/features/reports/production_report.dart';
import 'package:agro_comercial/features/reports/production_report_calculator.dart';

// Trator T250 da planilha "custos da hora maquina"
const _t250 = MachineCostData(
  acquisitionValue: 1870399.42077953,
  scrapPercent: 20,
  usefulLifeHours: 10000,
  maintenancePercent: 100,
  marketValue: 650000,
  insuranceRate: 1.2,
  interestRate: 8,
  fuelConsumption: 30,
);

MachineModel _machine(String id, MachineCostData? data, {bool motor = true}) {
  return MachineModel(
    id: id,
    name: 'Máquina $id',
    brand: 'Marca',
    model: 'X',
    power: '250cv',
    workingHours: 0,
    warehouseId: 'w1',
    farmId: 'f1',
    isMotorized: motor,
    costData: data,
  );
}

FarmModel _farm({String unit = AreaUnits.hectare}) {
  return FarmModel(
    id: 'f1',
    name: 'Fazenda Teste',
    cadPro: '1',
    address: '',
    totalArea: '40',
    areaUnit: unit,
    plots: [
      PlotModel.fromMap({'name': 'Talhão 1', 'area': 10.0, 'crop': 'Soja'}),
      PlotModel.fromMap({'name': 'Talhão 2', 'area': 30.0, 'crop': 'Milho'}),
    ],
  );
}

final _product = ProductModel(
  id: 'p1',
  name: 'Fungicida',
  brand: 'Marca',
  quantity: 10,
  measure: 20,
  unit: 'L',
  category: 'Fungicida',
  warehouseId: 'w1',
  farmId: 'f1',
  attributes: const {'campo_extra_1': 'Azoxistrobina'},
  unitPrice: 30, // preço atual (o lançamento guardou 25)
);

int _ts(int year, int month, int day) =>
    DateTime(year, month, day).millisecondsSinceEpoch;

// Safra 2025/26: 365 dias
final _period = ReportPeriod.cropYear(2025);

void main() {
  group('MachineCostData (planilha de custo da hora-máquina)', () {
    test('reproduz o Trator T250', () {
      expect(_t250.scrapValue, closeTo(374079.88, 0.01));
      expect(_t250.depreciationPerHour, closeTo(149.63, 0.01));
      expect(_t250.maintenancePerHour, closeTo(187.04, 0.01));
      expect(_t250.fixedCostPerHour, closeTo(336.67, 0.01));
      expect(_t250.annualInterestAndInsurance, closeTo(59800, 0.01));
      expect(_t250.fuelCostPerHour(6.13), closeTo(183.90, 0.001));
    });

    test('bem depreciado zera só a depreciação (colheitadeira 9470STS)', () {
      const combine = MachineCostData(
        acquisitionValue: 514540.84710993,
        scrapPercent: 20,
        usefulLifeHours: 4500,
        maintenancePercent: 50,
        marketValue: 426400,
        insuranceRate: 1.2,
        interestRate: 8,
        fullyDepreciated: true,
      );
      expect(combine.depreciationPerHour, 0);
      expect(combine.fixedCostPerHour, closeTo(57.17, 0.01));
      expect(combine.annualInterestAndInsurance, closeTo(39228.8, 0.01));
    });

    test('sem vida útil não divide por zero', () {
      const incomplete = MachineCostData(acquisitionValue: 1000);
      expect(incomplete.isComplete, isFalse);
      expect(incomplete.fixedCostPerHour, 0);
    });
  });

  group('ProductionQuantities', () {
    test('soma sacas, kg e toneladas na unidade do primeiro registro', () {
      final q = ProductionQuantities()
        ..add(1, HarvestUnits.bag)
        ..add(60, HarvestUnits.kilogram)
        ..add(0.06, HarvestUnits.ton);
      expect(q.isSingleUnit, isTrue);
      expect(q.unit, HarvestUnits.bag);
      expect(q.quantity, closeTo(3, 1e-9));
    });

    test('mantém separadas unidades sem conversão', () {
      final q = ProductionQuantities()
        ..add(10, HarvestUnits.bag)
        ..add(5, HarvestUnits.box);
      expect(q.isSingleUnit, isFalse);
      expect(q.quantity, 0);
    });
  });

  group('ReportPeriod', () {
    test('safra atual vai de julho a junho', () {
      final p = ReportPeriod.currentCropYear(DateTime(2026, 3, 10));
      expect(p.start, DateTime(2025, 7, 1));
      expect(p.end, DateTime(2026, 6, 30));
      expect(p.days, 365);
      expect(p.contains(_ts(2026, 6, 30) + 23 * 3600 * 1000), isTrue);
      expect(p.contains(_ts(2026, 7, 1)), isFalse);
    });
  });

  group('ProductionReportCalculator', () {
    ProductionReport build({
      List<OperationModel> operations = const [],
      List<FieldOperationModel> fieldOperations = const [],
      List<CostModel> costs = const [],
      List<HarvestModel> harvests = const [],
      List<MachineModel>? machines,
      FarmModel? farm,
      double diesel = 6.13,
    }) {
      return ProductionReportCalculator.build(
        farms: [
          FarmReportInput(
            farm: farm ?? _farm(),
            operations: operations,
            fieldOperations: fieldOperations,
            costs: costs,
            harvests: harvests,
            machines: machines ?? [_machine('m1', _t250)],
            products: [_product],
          ),
        ],
        period: _period,
        dieselPrice: diesel,
      );
    }

    final operation = OperationModel(
      title: 'Pulverização - pragas e doenças',
      description: '',
      farmId: 'f1',
      dateTimestamp: _ts(2025, 11, 10),
      plotName: 'Talhão 1',
      usedMachine: true,
      machineId: 'm1',
      machineName: 'Trator T250',
      machineHours: 2,
      usedProducts: true,
      appliedProducts: [
        {
          'productId': 'p1',
          'productName': 'Fungicida',
          'dosage': 20000.0,
          'dosageUnit': 'ml',
          'unitPrice': 25.0,
          'productUnit': 'L',
        },
      ],
    );

    test('custo do talhão: insumos, máquina, diesel e juros/seguro', () {
      final report = build(operations: [operation]);
      final plot = report.plots.first.summary;

      // 20.000 ml = 20 L x R$ 25 (preço do dia, não o atual de R$ 30)
      expect(plot.costByGroup[ExpenseGroup.insumos], closeTo(500, 1e-6));
      expect(plot.costByGroup[ExpenseGroup.maquinas], closeTo(673.34, 0.01));
      expect(plot.costByGroup[ExpenseGroup.combustivel], closeTo(367.8, 1e-6));
      // Juros + seguro anual (59.800) x 365/365, 25% da área
      expect(plot.costByGroup[ExpenseGroup.juros], closeTo(14950, 0.01));

      final line = report.plots.first.inputs.single;
      expect(line.quantity, closeTo(20, 1e-9));
      expect(line.formulation, 'Azoxistrobina');
      expect(line.isShared, isFalse);

      // O outro talhão só recebe o rateio de juros/seguro (75%)
      final other = report.plots[1].summary;
      expect(other.costByGroup[ExpenseGroup.insumos], isNull);
      expect(other.totalCost, closeTo(44850, 0.01));
    });

    test('custo sem talhão é rateado pela área e por hora é ignorado', () {
      final report = build(
        machines: const [],
        costs: [
          CostModel(
            farmId: 'f1',
            type: CostCategories.fixed,
            category: 'Arrendamento',
            value: 4000,
            dateTimestamp: _ts(2025, 8, 1),
          ),
          CostModel(
            farmId: 'f1',
            type: CostCategories.fixed,
            category: 'Depreciação de Máquinas',
            value: 149.63,
            dateTimestamp: _ts(2025, 8, 1),
          ),
          // Fora do período
          CostModel(
            farmId: 'f1',
            type: CostCategories.variable,
            category: 'Fretes',
            value: 999,
            dateTimestamp: _ts(2024, 8, 1),
            plotName: 'Talhão 1',
          ),
        ],
      );

      expect(
        report.plots[0].summary.costByGroup[ExpenseGroup.arrendamento],
        closeTo(1000, 1e-9),
      );
      expect(
        report.plots[1].summary.costByGroup[ExpenseGroup.arrendamento],
        closeTo(3000, 1e-9),
      );
      expect(report.total.totalCost, closeTo(4000, 1e-9));
      expect(report.warnings.ignoredHourlyCosts, 1);
      expect(report.warnings.sharedRecords, 1);
    });

    test('produção: produtividade, margem e custo por saca', () {
      final report = build(
        machines: const [],
        costs: [
          CostModel(
            farmId: 'f1',
            type: CostCategories.variable,
            category: 'Serviços contratados',
            value: 50000,
            dateTimestamp: _ts(2025, 9, 1),
            plotName: 'talhão 1', // maiúsculas/minúsculas não importam
          ),
        ],
        harvests: [
          HarvestModel(
            farmId: 'f1',
            plotName: 'Talhão 1',
            crop: 'Soja',
            dateTimestamp: _ts(2026, 2, 20),
            quantity: 600,
            unit: HarvestUnits.bag,
            unitPrice: 115,
          ),
        ],
      );
      final s = report.plots.first.summary;

      expect(s.revenue, 69000);
      expect(s.productivityPerHa, closeTo(60, 1e-9));
      expect(s.costPerHa, closeTo(5000, 1e-9));
      expect(s.margin, closeTo(19000, 1e-9));
      expect(s.costPerUnit, closeTo(83.33, 0.01));
      // R$ 5.000/ha / R$ 115 = 43,48 sc/ha pagam o custo
      expect(s.breakEvenPerHa, closeTo(43.48, 0.01));

      expect(report.byCrop.map((c) => c.name), containsAll(['Soja', 'Milho']));
      expect(report.byFarm.single.revenue, 69000);
    });

    test('aplicação usa o preço atual quando o lançamento não tem preço', () {
      final report = build(
        machines: const [],
        fieldOperations: [
          FieldOperationModel(
            type: 'Aplicação',
            plotName: 'Talhão 2',
            dateTimestamp: _ts(2025, 12, 1),
            farmId: 'f1',
            productId: 'p1',
            productName: 'Fungicida',
            dosage: 3,
            dosageUnit: 'L',
          ),
          // Vistoria não gera custo
          FieldOperationModel(
            type: 'Vistoria',
            plotName: 'Talhão 2',
            dateTimestamp: _ts(2025, 12, 1),
            farmId: 'f1',
          ),
        ],
      );
      expect(
        report.plots[1].summary.costByGroup[ExpenseGroup.insumos],
        closeTo(90, 1e-9),
      );
      expect(report.warnings.sharedRecords, 0);
    });

    test('implemento acoplado soma as mesmas horas do trator', () {
      const planter = MachineCostData(
        acquisitionValue: 196090.26185592,
        scrapPercent: 20,
        usefulLifeHours: 5000,
        maintenancePercent: 80,
        fullyDepreciated: true,
      );
      final report = build(
        diesel: 0,
        machines: [
          _machine('m1', _t250),
          _machine('m2', planter, motor: false),
        ],
        operations: [
          operation.copyWith(
            usedProducts: false,
            appliedProducts: const [],
            implementId: 'm2',
            implementName: 'Plantadeira',
          ),
        ],
      );
      final plot = report.plots.first;
      expect(plot.machines, hasLength(2));
      // 2 h x (336,67 + 31,37)
      expect(
        plot.summary.costByGroup[ExpenseGroup.maquinas],
        closeTo(2 * (336.67 + 31.37), 0.05),
      );
      expect(report.warnings.dieselPriceMissing, isTrue);
      expect(
        report.machineRows
            .firstWhere((r) => r.machine.id == 'm2')
            .hoursInPeriod,
        2,
      );
    });

    test('fazenda em alqueires converte a área para hectares', () {
      final report = build(
        farm: _farm(unit: AreaUnits.alqueire),
        machines: const [],
      );
      expect(report.plots.first.areaHa, closeTo(24.2, 1e-9));

      const display = AreaDisplay(AreaUnits.alqueire);
      expect(display.area(24.2), closeTo(10, 1e-9));
      expect(display.perArea(100), closeTo(242, 1e-9));
    });

    test('lançamento de talhão removido entra no rateio e gera aviso', () {
      final report = build(
        machines: const [],
        costs: [
          CostModel(
            farmId: 'f1',
            type: CostCategories.variable,
            category: 'Fretes',
            value: 400,
            dateTimestamp: _ts(2025, 8, 1),
            plotName: 'Talhão Antigo',
          ),
        ],
      );
      expect(report.warnings.unmatchedPlotRecords, 1);
      expect(report.total.totalCost, closeTo(400, 1e-9));
      expect(report.plots[0].expenses.single.isShared, isTrue);
    });

    test('talhão renomeado continua com os lançamentos antigos e novos', () {
      // Fazenda gravada antes dos ids: o talhão recebe o id derivado do nome
      final legacyFarm = FarmModel.fromMap({
        'id': 'f1',
        'name': 'Fazenda Teste',
        'totalArea': '40',
        'plantedFields': [
          {'name': 'Talhão 1', 'area': 10.0, 'crop': 'Soja'},
          {'name': 'Talhão 2', 'area': 30.0, 'crop': 'Milho'},
        ],
      });
      final legacyId = legacyFarm.plots[0].id;

      // Edição da fazenda: renomeia o Talhão 1 (mantém o id)
      final renamed = legacyFarm.plots[0].update(
        name: 'Talhão Norte',
        area: 10,
        crop: 'Soja',
      );
      final farm = FarmModel.fromMap(
        FarmModel(
          id: 'f1',
          name: 'Fazenda Teste',
          cadPro: '1',
          address: '',
          totalArea: '40',
          plots: [renamed, legacyFarm.plots[1]],
        ).toMap(),
      );
      expect(farm.plots[0].id, legacyId);

      CostModel cost(double value, {String? plotId, String? plotName}) =>
          CostModel(
            farmId: 'f1',
            type: CostCategories.variable,
            category: 'Fretes',
            value: value,
            dateTimestamp: _ts(2025, 8, 1),
            plotId: plotId,
            plotName: plotName,
          );

      final report = build(
        farm: farm,
        machines: const [],
        costs: [
          cost(100, plotName: 'Talhão 1'), // antes dos ids, só com o nome
          cost(50, plotId: legacyId, plotName: 'Talhão 1'), // com o id
          cost(25, plotId: legacyId, plotName: 'Talhão Norte'), // depois
        ],
      );

      expect(report.warnings.unmatchedPlotRecords, 0);
      expect(report.warnings.sharedRecords, 0);
      final plot = report.plots[0];
      expect(plot.plotName, 'Talhão Norte');
      expect(plot.expenses.length, 3);
      expect(plot.expenses.any((e) => e.isShared), isFalse);
      expect(report.plots[1].expenses, isEmpty);
    });
  });
}
