import 'package:flutter/material.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/services/cost_service/cost_service.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';

abstract class CostState {}

class CostInitialState extends CostState {}

class CostLoadingState extends CostState {}

class CostSuccessState extends CostState {
  final List<CostModel> costs;
  CostSuccessState(this.costs);
}

class CostErrorState extends CostState {
  final String message;
  CostErrorState(this.message);
}

class CostController extends ChangeNotifier {
  final CostService _costService;

  CostController(this._costService);

  CostState _state = CostInitialState();
  CostState get state => _state;

  List<CostModel> allCosts = [];

  // ==========================================
  // CÁLCULOS METODOLOGIA OCEPAR
  // ==========================================

  // Variáveis: Manutenção Tratores (CR = (Vi * 60%) / Vuh)
  double calcManutencaoTrator(double vi, double vuh) => (vi * 0.60) / vuh;

  // Variáveis: Manutenção Implementos (CR = (Vi * R%) / Vuh)
  double calcManutencaoImplemento(double vi, double r, double vuh) =>
      (vi * (r / 100)) / vuh;

  // Fixos: Depreciação Máquinas (D = (Vi - Vs) / Vuh)
  double calcDepreciacaoMaquina(double vi, double vs, double vuh) =>
      (vi - vs) / vuh;

  // Fixos: Depreciação Benfeitorias (D = (Vi - Vs) / Vua)
  double calcDepreciacaoBenfeitoria(double vi, double vs, double vua) =>
      (vi - vs) / vua;

  // Fixos: Seguro Máquinas (S = (Vm * 0.75%) / Uah) -> Vm = (Vi+Vs)/2
  double calcSeguroMaquina(double vm, double uah) => (vm * 0.0075) / uah;

  // Fixos: Seguro Benfeitorias (S = Vm * 0.35%)
  double calcSeguroBenfeitoria(double vm) => vm * 0.0035;

  // Fixos: Juros sobre Terras (J = Vt * 3.00% a.a.)
  double calcJurosTerra(double vt) => vt * 0.03;

  // Fixos: Juros sobre Máquinas (J = (Vm * 6%) / Uah)
  double calcJurosMaquina(double vm, double uah) => (vm * 0.06) / uah;

  // Fixos: Juros sobre Benfeitorias (J = Vm * 6%)
  double calcJurosBenfeitoria(double vm) => vm * 0.06;

  // ==========================================
  // GERENCIAMENTO NO BANCO DE DADOS
  // ==========================================

  Future<void> loadCosts() async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId != null) {
        allCosts = await _costService.getCostsByFarm(activeFarmId);
        _state = CostSuccessState(allCosts);
      } else {
        _state = CostErrorState("Nenhuma fazenda ativa selecionada.");
      }
    } catch (e) {
      _state = CostErrorState("Erro ao carregar custos.");
    }
    notifyListeners();
  }

  Future<void> saveCost(CostModel cost) async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      // Garante que o custo seja salvo na fazenda ativa
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId == null) throw Exception("Fazenda não selecionada");

      final costToSave = CostModel(
        farmId: activeFarmId,
        type: cost.type,
        category: cost.category,
        value: cost.value,
        dateTimestamp: cost.dateTimestamp,
        observation: cost.observation,
        calculationData: cost.calculationData,
      );

      await _costService.saveCost(costToSave);
      await loadCosts();
    } catch (e) {
      _state = CostErrorState("Erro ao salvar o custo.");
      notifyListeners();
    }
  }

  Future<void> updateCost(CostModel cost) async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      await _costService.updateCost(cost);
      await loadCosts();
    } catch (e) {
      _state = CostErrorState("Erro ao atualizar o custo.");
      notifyListeners();
    }
  }

  Future<void> deleteCost(String costId) async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      await _costService.deleteCost(costId);
      await loadCosts();
    } catch (e) {
      _state = CostErrorState("Erro ao excluir o custo.");
      notifyListeners();
    }
  }

  Future<void> deleteSelectedCosts(List<String> ids) async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      for (var id in ids) {
        await _costService.deleteCost(id);
      }
      await loadCosts();
    } catch (e) {
      _state = CostErrorState("Erro ao excluir custos selecionados.");
      notifyListeners();
    }
  }
}
