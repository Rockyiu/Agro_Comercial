import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/services/harvest_service/harvest_service.dart';
import 'harvest_state.dart';

// Produção colhida por talhão (base da receita nos relatórios de custo)
class HarvestController extends SafeChangeNotifier {
  final HarvestService _harvestService;
  final FarmController _farmController;

  HarvestController(this._harvestService, this._farmController);

  HarvestState _state = HarvestInitialState();
  HarvestState get state => _state;

  // Colaborador vê apenas as colheitas que ele mesmo registrou
  bool onlyMine = false;

  void _changeState(HarvestState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadHarvests() async {
    _changeState(HarvestLoadingState());
    try {
      final farmId = _farmController.selectedFarm?.id;
      if (farmId == null) {
        _changeState(HarvestErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }
      var harvests = await _harvestService.getHarvests(farmId);
      if (onlyMine) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        harvests = harvests.where((h) => h.createdBy == uid).toList();
      }
      _changeState(HarvestSuccessState(harvests));
    } catch (e) {
      debugPrint("Erro ao carregar colheitas: $e");
      _changeState(HarvestErrorState("Erro ao carregar a produção."));
    }
  }

  Future<void> saveHarvest(HarvestModel harvest) async {
    _changeState(HarvestLoadingState());
    try {
      final farmId = _farmController.selectedFarm?.id;
      if (farmId == null) {
        _changeState(HarvestErrorState("Nenhuma fazenda ativa selecionada."));
        return;
      }
      await _harvestService.createHarvest(
        harvest.copyWith(
          farmId: farmId,
          createdBy: FirebaseAuth.instance.currentUser?.uid,
        ),
      );
      await loadHarvests();
    } catch (e) {
      debugPrint("Erro ao salvar colheita: $e");
      _changeState(HarvestErrorState("Erro ao salvar a colheita."));
    }
  }

  Future<void> updateHarvest(HarvestModel harvest) async {
    _changeState(HarvestLoadingState());
    try {
      await _harvestService.updateHarvest(harvest);
      await loadHarvests();
    } catch (e) {
      debugPrint("Erro ao atualizar colheita: $e");
      _changeState(HarvestErrorState("Erro ao atualizar a colheita."));
    }
  }

  Future<void> deleteHarvest(String id) async {
    _changeState(HarvestLoadingState());
    try {
      await _harvestService.deleteHarvest(id);
      await loadHarvests();
    } catch (e) {
      debugPrint("Erro ao excluir colheita: $e");
      _changeState(HarvestErrorState("Erro ao excluir a colheita."));
    }
  }
}
