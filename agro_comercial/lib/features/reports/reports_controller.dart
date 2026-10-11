import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/services/cost_service/cost_service.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/harvest_service/harvest_service.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'package:agro_comercial/services/stock_service/stock_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'production_report.dart';
import 'production_report_calculator.dart';
import 'reports_state.dart';

// Abrangência dos relatórios
enum ReportScope { activeFarm, allFarms }

// Relatórios de custo de produção (por talhão, propriedade e cultura) e de
// custo da hora-máquina, montados com os dados lançados no sistema.
class ReportsController extends SafeChangeNotifier {
  final FarmController _farmController;
  final OperationService _operationService;
  final FieldOperationService _fieldOperationService;
  final CostService _costService;
  final HarvestService _harvestService;
  final StockService _stockService;

  ReportsController(
    this._farmController,
    this._operationService,
    this._fieldOperationService,
    this._costService,
    this._harvestService,
    this._stockService,
  );

  static const _dieselPriceKey = 'report_diesel_price';
  static const _areaUnitKey = 'report_area_unit';

  ReportsState _state = ReportsInitialState();
  ReportsState get state => _state;

  ReportScope scope = ReportScope.activeFarm;
  ReportPeriod period = ReportPeriod.currentCropYear();
  double dieselPrice = 0;
  String areaUnit = AreaUnits.hectare;

  AreaDisplay get areaDisplay => AreaDisplay(areaUnit);

  // Dados brutos já buscados: mudar período ou diesel só recalcula
  List<FarmReportInput>? _inputs;
  ReportScope? _loadedScope;
  String? _loadedActiveFarmId;

  void _changeState(ReportsState newState) {
    _state = newState;
    notifyListeners();
  }

  // Preço do diesel e unidade de área usados por último
  Future<void> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      dieselPrice = prefs.getDouble(_dieselPriceKey) ?? 0;
      areaUnit =
          prefs.getString(_areaUnitKey) ??
          _farmController.selectedFarm?.areaUnit ??
          AreaUnits.hectare;
    } catch (e) {
      debugPrint("Erro ao carregar preferências dos relatórios: $e");
    }
  }

  Future<void> load({bool forceRefresh = false}) async {
    final activeFarmId = _farmController.selectedFarm?.id;
    final needsFetch =
        forceRefresh ||
        _inputs == null ||
        _loadedScope != scope ||
        _loadedActiveFarmId != activeFarmId;

    if (!needsFetch) {
      _recalculate();
      return;
    }

    _changeState(ReportsLoadingState());
    try {
      final farms = await _farmsInScope();
      if (farms.isEmpty) {
        _changeState(ReportsErrorState("Nenhuma fazenda encontrada."));
        return;
      }
      _inputs = await Future.wait(farms.map(_fetchFarm));
      _loadedScope = scope;
      _loadedActiveFarmId = activeFarmId;
      _recalculate();
    } catch (e) {
      debugPrint("Erro ao carregar dados dos relatórios: $e");
      _changeState(
        ReportsErrorState("Erro ao carregar os dados dos relatórios."),
      );
    }
  }

  Future<List<FarmModel>> _farmsInScope() async {
    if (scope == ReportScope.allFarms) {
      return _farmController.fetchOwnedFarms();
    }
    final farm = _farmController.selectedFarm;
    return farm == null ? [] : [farm];
  }

  // Todos os lançamentos de uma fazenda, buscados em paralelo
  Future<FarmReportInput> _fetchFarm(FarmModel farm) async {
    final farmId = farm.id!;
    final (operations, fieldOperations, costs, harvests, resources) = await (
      _operationService.getOperations(farmId),
      _fieldOperationService.getFieldOperations(farmId),
      _costService.getCostsByFarm(farmId, includeLabor: true),
      _harvestService.getHarvests(farmId),
      _stockService.loadFarmResources(farmId, withCosts: true),
    ).wait;

    return FarmReportInput(
      farm: farm,
      operations: operations,
      fieldOperations: fieldOperations,
      costs: costs,
      harvests: harvests,
      machines: resources.machines,
      products: resources.products,
    );
  }

  void _recalculate() {
    final inputs = _inputs;
    if (inputs == null) return;
    _changeState(
      ReportsSuccessState(
        ProductionReportCalculator.build(
          farms: inputs,
          period: period,
          dieselPrice: dieselPrice,
        ),
      ),
    );
  }

  void changeScope(ReportScope newScope) {
    if (scope == newScope) return;
    scope = newScope;
    load();
  }

  void changePeriod(ReportPeriod newPeriod) {
    period = newPeriod;
    _recalculate();
  }

  Future<void> changeDieselPrice(double price) async {
    if (price == dieselPrice) return;
    dieselPrice = price;
    _recalculate();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_dieselPriceKey, price);
    } catch (e) {
      debugPrint("Erro ao salvar o preço do diesel: $e");
    }
  }

  Future<void> changeAreaUnit(String unit) async {
    areaUnit = unit;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_areaUnitKey, unit);
    } catch (e) {
      debugPrint("Erro ao salvar a unidade de área: $e");
    }
  }
}
