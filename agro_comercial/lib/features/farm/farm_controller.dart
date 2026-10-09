import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/services/farm_service/farm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmController extends SafeChangeNotifier {
  final FarmService _farmService;

  FarmController(this._farmService);

  List<FarmModel> farms = [];
  FarmModel? selectedFarm;
  bool isLoading = false;

  Future<void> loadFarms() async {
    isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        farms = await _farmService.getFarmsByOwner(user.uid);

        if (farms.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final savedFarmId = prefs.getString('selected_farm_id');

          selectedFarm = farms.firstWhere(
            (f) => f.id == savedFarmId,
            orElse: () => farms.first,
          );
        } else {
          selectedFarm = null;
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar fazendas: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Busca atualizada das fazendas do produtor (para o seletor "Trocar de
  // Fazenda"). Diferente de loadFarms, repassa o erro para a tela avisar.
  Future<List<FarmModel>> fetchOwnedFarms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    farms = await _farmService.getFarmsByOwner(user.uid);
    notifyListeners();
    return farms;
  }

  // O colaborador não é dono de fazendas: a fazenda ativa dele é a que o
  // produtor vinculou ao seu cadastro na tela "Minha Equipe".
  Future<void> loadCollaboratorFarm() async {
    isLoading = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final farm = await _farmService.getFarmByCollaborator(user.uid);
        farms = farm != null ? [farm] : [];
        selectedFarm = farm;
      }
    } catch (e) {
      debugPrint("Erro ao buscar fazenda do colaborador: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Em caso de erro, a exceção chega à tela, que avisa o usuário
  Future<void> updateFarm(FarmModel updatedFarm) async {
    await _farmService.updateFarm(updatedFarm);

    // A fazenda ativa reflete a edição na hora
    if (selectedFarm?.id == updatedFarm.id) selectedFarm = updatedFarm;

    // Recarrega a lista de fazendas (e avisa as telas)
    await loadFarms();
  }

  // Ao sair da conta: nada da fazenda anterior pode aparecer para o próximo
  // usuário que entrar no aparelho
  void clear() {
    farms = [];
    selectedFarm = null;
    notifyListeners();
  }

  Future<void> changeActiveFarm(FarmModel farm) async {
    selectedFarm = farm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_farm_id', farm.id ?? '');
    notifyListeners();
  }
}
