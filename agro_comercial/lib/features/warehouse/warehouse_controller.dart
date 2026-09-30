import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'warehouse_state.dart';

class WarehouseController extends SafeChangeNotifier {
  final WarehouseService _warehouseService;
  final FarmController _farmController;

  WarehouseController(this._warehouseService, this._farmController);

  WarehouseState _state = WarehouseInitialState();
  WarehouseState get state => _state;

  Future<void> loadWarehouseData() async {
    _state = WarehouseLoadingState();
    notifyListeners();
    try {
      // Armazéns da fazenda selecionada no menu
      final activeFarmId = _farmController.selectedFarm?.id;

      if (activeFarmId != null) {
        final warehouses = await _warehouseService.getWarehouses(activeFarmId);
        _state = WarehouseSuccessState(warehouses: warehouses);
      } else {
        _state = WarehouseErrorState("Nenhuma fazenda ativa.");
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
