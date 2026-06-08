import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'warehouse_state.dart';

class WarehouseController extends ChangeNotifier {
  final WarehouseService _warehouseService;

  WarehouseController(this._warehouseService);

  WarehouseState _state = WarehouseInitialState();
  WarehouseState get state => _state;

  Future<void> loadWarehouseData() async {
    _state = WarehouseLoadingState();
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final warehouses = await _warehouseService.getWarehouses(user.uid);

        // CORRIGIDO: Passando os parâmetros nomeados exigidos pelo WarehouseSuccessState
        _state = WarehouseSuccessState(
          warehouses: warehouses,
          machines:
              [], // Como a Home só lista os galpões, passamos vazio aqui safely
        );
      } else {
        _state = WarehouseErrorState("Usuário não autenticado.");
      }
      notifyListeners();
    } catch (e) {
      _state = WarehouseErrorState("Erro ao carregar armazéns.");
      notifyListeners();
    }
  }

  Future<void> deleteSelectedWarehouses(List<String> ids) async {
    _state = WarehouseLoadingState();
    notifyListeners();
    try {
      await _warehouseService.deleteMultipleWarehouses(ids);
      await loadWarehouseData();
    } catch (e) {
      _state = WarehouseErrorState("Erro ao excluir armazéns.");
      notifyListeners();
    }
  }
}
