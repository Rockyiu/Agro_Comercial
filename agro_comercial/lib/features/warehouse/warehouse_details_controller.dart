import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/machine_model.dart';

// --- ESTADOS DA TELA ---
abstract class WarehouseDetailsState {}

class WarehouseDetailsInitialState extends WarehouseDetailsState {}

class WarehouseDetailsLoadingState extends WarehouseDetailsState {}

class WarehouseDetailsSuccessState extends WarehouseDetailsState {
  final List<MachineModel> machines;
  WarehouseDetailsSuccessState(this.machines);
}

class WarehouseDetailsErrorState extends WarehouseDetailsState {
  final String message;
  WarehouseDetailsErrorState(this.message);
}

// --- O CONTROLADOR ---
class WarehouseDetailsController extends ChangeNotifier {
  final MachineService _machineService;

  WarehouseDetailsController(this._machineService);

  WarehouseDetailsState _state = WarehouseDetailsInitialState();
  WarehouseDetailsState get state => _state;

  Future<void> loadMachines(String warehouseId) async {
    _state = WarehouseDetailsLoadingState();
    notifyListeners();

    try {
      // Usa o serviço que criamos antes para buscar só as máquinas Deste armazém
      final machines = await _machineService.getMachinesByWarehouse(
        warehouseId,
      );

      _state = WarehouseDetailsSuccessState(machines);
      notifyListeners();
    } catch (e) {
      _state = WarehouseDetailsErrorState("Erro ao carregar o estoque.");
      notifyListeners();
    }
  }
}
