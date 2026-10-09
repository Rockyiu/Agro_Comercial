import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:async';

import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'warehouse_details_state.dart';

class WarehouseDetailsController extends SafeChangeNotifier {
  final MachineService _machineService;
  final ProductService _productService;

  WarehouseDetailsController(this._machineService, this._productService);

  WarehouseDetailsState _state = WarehouseDetailsInitialState();
  WarehouseDetailsState get state => _state;

  Future<void> loadInventory(WarehouseModel warehouse) async {
    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      // Carrega ambos em paralelo do Firebase
      final (machines, products) = await (
        _machineService.getMachinesByWarehouse(
          farmId: warehouse.farmId,
          warehouseId: warehouse.id!,
        ),
        _productService.getProductsByWarehouse(
          farmId: warehouse.farmId,
          warehouseId: warehouse.id!,
        ),
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

  // Apaga os itens selecionados, separando máquinas de produtos pelo que
  // está carregado na tela (cada serviço recebe só os IDs que são seus)
  Future<void> deleteSelectedItems(
    List<String> ids,
    WarehouseModel warehouse,
  ) async {
    final current = _state;
    if (current is! WarehouseDetailsSuccessState) return;
    final selected = ids.toSet();
    final machineIds = [
      for (final m in current.machines)
        if (selected.contains(m.id)) m.id!,
    ];
    final productIds = [
      for (final p in current.products)
        if (selected.contains(p.id)) p.id!,
    ];

    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      await Future.wait([
        if (machineIds.isNotEmpty)
          _machineService.deleteMultipleMachines(machineIds),
        if (productIds.isNotEmpty)
          _productService.deleteMultipleProducts(productIds),
      ]);

      await loadInventory(warehouse);
    } catch (e) {
      _state = WarehouseDetailsErrorState("Erro ao processar a exclusão.");
      notifyListeners();
    }
  }
}
