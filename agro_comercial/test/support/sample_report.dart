import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/plot_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/features/reports/production_report_calculator.dart';
import 'package:agro_comercial/features/reports/production_report.dart';

MachineModel _machine(String id, String name, MachineCostData data) {
  return MachineModel(
    id: id,
    name: name,
    brand: 'Marca',
    model: '',
    power: '',
    workingHours: 0,
    warehouseId: 'w1',
    farmId: 'f1',
    isMotorized: (data.fuelConsumption ?? 0) > 0,
    costData: data,
  );
}

ProductModel _product(String id, String name, String unit, double price) {
  return ProductModel(
    id: id,
    name: name,
    brand: 'Marca',
    quantity: 100,
    measure: 1,
    unit: unit,
    category: 'Fungicida',
    warehouseId: 'w1',
    farmId: 'f1',
    attributes: {'campo_extra_1': 'Princípio ativo de $name'},
    unitPrice: price,
  );
}

int _ts(int month, int day) =>
    DateTime(month >= 7 ? 2025 : 2026, month, day).millisecondsSinceEpoch;

OperationModel _op(
  String title,
  int date, {
  String? plot,
  String? machine,
  double? hours,
  String? implement,
  List<Map<String, dynamic>> products = const [],
}) {
  return OperationModel(
    title: title,
    description: '',
    farmId: 'f1',
    dateTimestamp: date,
    plotName: plot,
    usedMachine: machine != null,
    machineId: machine,
    machineHours: hours,
    implementId: implement,
    implementName: implement == null ? null : 'Plantadeira JD 1100',
    usedProducts: products.isNotEmpty,
    appliedProducts: products,
  );
}

Map<String, dynamic> _use(String id, String name, double dosage, String unit) =>
    {
      'productId': id,
      'productName': name,
      'dosage': dosage,
      'dosageUnit': unit,
    };

// Fazenda de exemplo com máquinas da planilha de custo da hora-máquina,
// usada nos testes dos PDFs e do painel
ProductionReport buildSampleReport() {
  final farm = FarmModel(
    id: 'f1',
    name: 'Fazenda Romagnolle',
    cadPro: '1',
    address: '',
    totalArea: '43',
    areaUnit: AreaUnits.alqueire,
    plots: [
      PlotModel.fromMap({'name': 'Talhão 12', 'area': 7.64, 'crop': 'Soja'}),
      PlotModel.fromMap({'name': 'Talhão 3', 'area': 20.0, 'crop': 'Soja'}),
      PlotModel.fromMap({'name': 'Talhão 5', 'area': 15.36, 'crop': 'Milho'}),
    ],
  );

  final machines = [
    _machine(
      'm1',
      'TRATOR AGRICOLA T250 VALTRA',
      const MachineCostData(
        acquisitionValue: 1870399.42,
        scrapPercent: 20,
        usefulLifeHours: 10000,
        maintenancePercent: 100,
        marketValue: 650000,
        insuranceRate: 1.2,
        interestRate: 8,
        fuelConsumption: 30,
      ),
    ),
    _machine(
      'm2',
      'PLANTADEIRA JOHN DEERE MOD 1100 DE 13 LINHAS',
      const MachineCostData(
        acquisitionValue: 196090.26,
        scrapPercent: 20,
        usefulLifeHours: 5000,
        maintenancePercent: 80,
        marketValue: 162500,
        interestRate: 8,
        fullyDepreciated: true,
      ),
    ),
    _machine(
      'm3',
      'PULVERIZADOR JOHN DEERE 4630',
      const MachineCostData(
        acquisitionValue: 578013.76,
        scrapPercent: 20,
        usefulLifeHours: 4000,
        maintenancePercent: 85,
        marketValue: 479000,
        insuranceRate: 1.2,
        interestRate: 8,
        fuelConsumption: 22,
        fullyDepreciated: true,
      ),
    ),
  ];
  final products = [
    _product('p1', 'ADUBO 04-30-10', 'kg', 2.9),
    _product('p2', 'FOX XPRO', 'L', 350),
    _product('p3', 'GLIFOSATO WG', 'kg', 26),
  ];

  return ProductionReportCalculator.build(
    period: ReportPeriod.cropYear(2025),
    dieselPrice: 6.13,
    farms: [
      FarmReportInput(
        farm: farm,
        machines: machines,
        products: products,
        operations: [
          _op(
            'Plantio - tratorizado',
            _ts(10, 5),
            plot: 'Talhão 12',
            machine: 'm1',
            hours: 12.7,
            implement: 'm2',
            products: [_use('p1', 'ADUBO 04-30-10', 12396, 'kg')],
          ),
          _op(
            'Pulverização - pragas e doenças',
            _ts(12, 2),
            plot: 'Talhão 12',
            machine: 'm3',
            hours: 6,
            products: [_use('p2', 'FOX XPRO', 92.5, 'L')],
          ),
          _op(
            'Pulverização - dessecação',
            _ts(9, 20),
            machine: 'm3',
            hours: 10,
            products: [_use('p3', 'GLIFOSATO WG', 350, 'kg')],
          ),
        ],
        costs: [
          CostModel(
            farmId: 'f1',
            type: CostCategories.variable,
            category: 'Mão-de-obra temporária',
            value: 11438,
            dateTimestamp: _ts(10, 30),
            observation: 'Diárias do plantio',
          ),
          CostModel(
            farmId: 'f1',
            type: CostCategories.fixed,
            category: 'Arrendamento',
            value: 64500,
            dateTimestamp: _ts(8, 1),
          ),
        ],
        harvests: [
          HarvestModel(
            farmId: 'f1',
            plotName: 'Talhão 12',
            crop: 'Soja',
            dateTimestamp: _ts(2, 25),
            quantity: 1100,
            unit: HarvestUnits.bag,
            unitPrice: 115,
          ),
        ],
      ),
    ],
  );
}
