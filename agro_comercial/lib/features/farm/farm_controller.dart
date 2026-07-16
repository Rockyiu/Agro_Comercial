import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/services/farm_service/farm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmController extends ChangeNotifier {
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

  Future<void> updateFarm(FarmModel updatedFarm) async {
    try {
      // 1. Manda o serviço atualizar no Firebase
      await _farmService.updateFarm(updatedFarm);

      // 2. Se a fazenda que o usuário acabou de editar for a mesma que está
      // ativa/selecionada no momento, atualiza a variável para refletir na hora!
      if (selectedFarm?.id == updatedFarm.id) {
        selectedFarm = updatedFarm;
      }

      // 3. Recarrega a lista de fazendas para a interface
      await loadFarms();
      notifyListeners();
    } catch (e) {
      throw Exception("Não foi possível atualizar a fazenda: $e");
    }
  }

  void setActiveFarm(FarmModel farm) {
    selectedFarm = farm;
    notifyListeners();
  }

  Future<void> changeActiveFarm(FarmModel farm) async {
    selectedFarm = farm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_farm_id', farm.id ?? '');
    notifyListeners();
  }
}
