import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'package:agro_comercial/locator.dart';

abstract class WarehouseDetailsState {}

class WarehouseDetailsInitialState extends WarehouseDetailsState {}

class WarehouseDetailsLoadingState extends WarehouseDetailsState {}

class WarehouseDetailsSuccessState extends WarehouseDetailsState {
  final List<MachineModel> machines;
  final List<ProductModel> products; // Adicionado à resposta de sucesso
  WarehouseDetailsSuccessState(this.machines, this.products);
}

class WarehouseDetailsErrorState extends WarehouseDetailsState {
  final String message;
  WarehouseDetailsErrorState(this.message);
}

class WarehouseDetailsController extends ChangeNotifier {
  final MachineService _machineService;
  final ProductService _productService = locator
      .get<ProductService>(); // Resgata o novo serviço

  WarehouseDetailsController(this._machineService);

  WarehouseDetailsState _state = WarehouseDetailsInitialState();
  WarehouseDetailsState get state => _state;

  Future<void> loadInventory(String warehouseId) async {
    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      // Carrega ambos em paralelo do Firebase
      final machines = await _machineService.getMachinesByWarehouse(
        warehouseId,
      );
      final products = await _productService.getProductsByWarehouse(
        warehouseId,
      );

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
      // Como os IDs do Firestore são únicos, podemos separar o lote de exclusão
      await _machineService.deleteMultipleMachines(ids);
      await _productService.deleteMultipleProducts(ids);

      await loadInventory(warehouseId);
    } catch (e) {
      _state = WarehouseDetailsErrorState("Erro ao processar a exclusão.");
      notifyListeners();
    }
  }
}
