import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';

abstract class EditWarehouseState {}

class EditWarehouseInitialState extends EditWarehouseState {}

class EditWarehouseLoadingState extends EditWarehouseState {}

class EditWarehouseSuccessState extends EditWarehouseState {}

class EditWarehouseErrorState extends EditWarehouseState {
  final String message;
  EditWarehouseErrorState(this.message);
}

class EditWarehouseController extends ChangeNotifier {
  final WarehouseService _warehouseService;

  EditWarehouseController(this._warehouseService);

  EditWarehouseState _state = EditWarehouseInitialState();
  EditWarehouseState get state => _state;

  Future<void> updateWarehouseName(
    WarehouseModel warehouse,
    String newName,
  ) async {
    _state = EditWarehouseLoadingState();
    notifyListeners();
    try {
      final updated = WarehouseModel(
        id: warehouse.id,
        name: newName,
        farmId: warehouse.farmId,
      );
      await _warehouseService.updateWarehouse(updated);
      _state = EditWarehouseSuccessState();
      notifyListeners();
    } catch (e) {
      _state = EditWarehouseErrorState("Erro ao atualizar o armazém.");
      notifyListeners();
    }
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    _state = EditWarehouseLoadingState();
    notifyListeners();
    try {
      await _warehouseService.deleteWarehouseAndContents(warehouseId);
      _state = EditWarehouseSuccessState();
      notifyListeners();
    } catch (e) {
      _state = EditWarehouseErrorState("Erro ao excluir o armazém.");
      notifyListeners();
    }
  }
}
