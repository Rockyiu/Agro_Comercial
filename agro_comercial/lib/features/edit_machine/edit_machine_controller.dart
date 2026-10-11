import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'edit_machine_state.dart';

class EditMachineController extends SafeChangeNotifier {
  final MachineService _machineService;

  EditMachineController(this._machineService);

  EditMachineState _state = EditMachineInitialState();
  EditMachineState get state => _state;

  // [hoursChanged]: o horímetro foi alterado no formulário (ver
  // MachineService.updateMachine)
  Future<void> updateMachineData(
    MachineModel updatedMachine, {
    required bool hoursChanged,
    PhotoChange? photo,
  }) async {
    _state = EditMachineLoadingState();
    notifyListeners();

    try {
      await _machineService.updateMachine(
        updatedMachine,
        updateHours: hoursChanged,
        photo: photo,
      );
      _state = EditMachineSuccessState();
      notifyListeners();
    } catch (e) {
      _state = EditMachineErrorState("Erro ao atualizar os dados da máquina.");
      notifyListeners();
    }
  }

  Future<void> deleteMachineData(String machineId) async {
    _state = EditMachineLoadingState();
    notifyListeners();
    try {
      await _machineService.deleteMachine(machineId);
      _state = EditMachineSuccessState();
      notifyListeners();
    } catch (e) {
      _state = EditMachineErrorState("Erro ao excluir a máquina.");
      notifyListeners();
    }
  }
}
