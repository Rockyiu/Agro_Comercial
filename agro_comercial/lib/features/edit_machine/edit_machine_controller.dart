import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:io'; // CORRIGIDO: Adicionado o import do File
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'edit_machine_state.dart';

class EditMachineController extends SafeChangeNotifier {
  final MachineService _machineService;

  EditMachineController(this._machineService);

  EditMachineState _state = EditMachineInitialState();
  EditMachineState get state => _state;

  Future<void> updateMachineData(
    MachineModel updatedMachine,
    File? newImageFile,
  ) async {
    _state = EditMachineLoadingState();
    notifyListeners();

    try {
      await _machineService.updateMachine(updatedMachine, newImageFile);
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
