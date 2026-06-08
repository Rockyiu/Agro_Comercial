import 'dart:io'; // CORRIGIDO: Adicionado o import do File
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';

// --- ESTADOS ---
abstract class EditMachineState {}

class EditMachineInitialState extends EditMachineState {}

class EditMachineLoadingState extends EditMachineState {}

class EditMachineSuccessState extends EditMachineState {}

class EditMachineErrorState extends EditMachineState {
  final String message;
  EditMachineErrorState(this.message);
}

// --- CONTROLADOR ---
class EditMachineController extends ChangeNotifier {
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
