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
