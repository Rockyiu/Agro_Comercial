import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
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
      // FILTRO MULTI-FAZENDA: Pega o ID da fazenda selecionada na tela principal
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;

      if (user != null && activeFarmId != null) {
        // Busca os armazéns filtrando pelo farmId (ID da fazenda) em vez de user.uid
        final warehouses = await _warehouseService.getWarehouses(activeFarmId);

        _state = WarehouseSuccessState(warehouses: warehouses, machines: []);
      } else {
        _state = WarehouseErrorState(
          "Usuário não autenticado ou sem fazenda selecionada.",
        );
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
