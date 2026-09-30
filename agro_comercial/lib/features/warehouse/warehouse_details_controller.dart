import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:async';

import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'warehouse_details_state.dart';

class WarehouseDetailsController extends SafeChangeNotifier {
  final MachineService _machineService;
  final ProductService _productService;

  WarehouseDetailsController(this._machineService, this._productService);

  WarehouseDetailsState _state = WarehouseDetailsInitialState();
  WarehouseDetailsState get state => _state;

  Future<void> loadInventory(String warehouseId) async {
    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      // Carrega ambos em paralelo do Firebase
      final (machines, products) = await (
        _machineService.getMachinesByWarehouse(warehouseId),
        _productService.getProductsByWarehouse(warehouseId),
      ).wait;

      _state = WarehouseDetailsSuccessState(machines, products);
      notifyListeners();
    } catch (e) {
      _state = WarehouseDetailsErrorState(
        "Erro ao carregar o estoque do armazém.",
      );
      notifyListeners();
    }
  }

  // Lógica inteligente para apagar itens selecionados (detecta se é máquina ou produto)
  Future<void> deleteSelectedItems(List<String> ids, String warehouseId) async {
    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      // Como os IDs do Firestore são únicos, os mesmos IDs podem ser enviados
      // para os dois serviços: cada um só apaga o que for seu
      await (
        _machineService.deleteMultipleMachines(ids),
        _productService.deleteMultipleProducts(ids),
      ).wait;

      await loadInventory(warehouseId);
    } catch (e) {
      _state = WarehouseDetailsErrorState("Erro ao processar a exclusão.");
      notifyListeners();
    }
  }
}
