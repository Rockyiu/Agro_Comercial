import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'edit_warehouse_state.dart';

class EditWarehouseController extends SafeChangeNotifier {
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

  Future<void> deleteWarehouse(WarehouseModel warehouse) async {
    _state = EditWarehouseLoadingState();
    notifyListeners();
    try {
      await _warehouseService.deleteWarehouseAndContents(warehouse);
      _state = EditWarehouseSuccessState();
      notifyListeners();
    } catch (e) {
      _state = EditWarehouseErrorState("Erro ao excluir o armazém.");
      notifyListeners();
    }
  }
}
