import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';
import 'package:agro_comercial/services/cost_service/cost_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'cost_state.dart';

class CostController extends SafeChangeNotifier {
  final CostService _costService;
  final AuthService _authService;
  final FarmController _farmController;

  CostController(this._costService, this._authService, this._farmController);

  CostState _state = CostInitialState();
  CostState get state => _state;

  List<CostModel> allCosts = [];

  // Colaborador não vê/edita custos de mão de obra. Em caso de erro assume
  // colaborador, por segurança.
  Future<bool> isCurrentUserCollaborator() async {
    try {
      return await _authService.isCurrentUserCollaborator();
    } catch (e) {
      debugPrint("Erro ao verificar o perfil do usuário: $e");
      return true;
    }
  }

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
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId != null) {
        // Custos de mão de obra (salários, diárias) são só do produtor: para
        // o colaborador, a própria consulta já vem sem eles
        final isCollaborator = await isCurrentUserCollaborator();
        allCosts = await _costService.getCostsByFarm(
          activeFarmId,
          includeLabor: !isCollaborator,
        );
        _state = CostSuccessState(allCosts);
      } else {
        _state = CostErrorState("Nenhuma fazenda ativa selecionada.");
      }
    } catch (e) {
      _state = CostErrorState("Erro ao carregar custos.");
    }
    notifyListeners();
  }

  // O formulário não conhece a fazenda: o custo é gravado na fazenda ativa,
  // com o id do talhão escolhido (para não perder o vínculo se ele for
  // renomeado)
  CostModel _inActiveFarm(CostModel cost) {
    final farm = _farmController.selectedFarm;
    if (farm?.id == null) throw Exception("Fazenda não selecionada");
    return cost.copyWith(
      farmId: farm!.id,
      plotId: farm.findPlot(name: cost.plotName)?.id,
    );
  }

  Future<void> saveCost(CostModel cost) async {
    _state = CostLoadingState();
    notifyListeners();
    try {
      await _costService.saveCost(_inActiveFarm(cost));
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
      await _costService.updateCost(_inActiveFarm(cost));
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
      await _costService.deleteCosts(ids);
      await loadCosts();
    } catch (e) {
      _state = CostErrorState("Erro ao excluir custos selecionados.");
      notifyListeners();
    }
  }
}
