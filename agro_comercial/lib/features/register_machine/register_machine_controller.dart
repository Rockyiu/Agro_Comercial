import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:agro_comercial/locator.dart'; // ADICIONADO
import 'package:agro_comercial/features/farm/farm_controller.dart'; // ADICIONADO

import 'register_machine_state.dart';

class RegisterMachineController extends ChangeNotifier {
  final MachineService _machineService;
  final WarehouseService _warehouseService;

  RegisterMachineController(this._machineService, this._warehouseService);

  RegisterMachineState _state = RegisterMachineInitialState();
  RegisterMachineState get state => _state;

  List<WarehouseModel> warehouses = [];
  bool isLoadingWarehouses = true;

  void _changeState(RegisterMachineState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadWarehouses() async {
    try {
      // CORREÇÃO: Carregar armazéns apenas da fazenda ativa para não vincular máquina a galpão errado
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId != null) {
        warehouses = await _warehouseService.getWarehouses(activeFarmId);
      }
    } catch (e) {
      debugPrint("Erro ao carregar armazéns: $e");
    } finally {
      isLoadingWarehouses = false;
      notifyListeners();
    }
  }

  Future<void> saveMachine({
    required String name,
    required String model,
    required String brand,
    required String power,
    required String workingHoursStr,
    required String warehouseId,
    required bool isMotorized,
    required File? imageFile,
  }) async {
    _changeState(RegisterMachineLoadingState());

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _changeState(RegisterMachineErrorState("Você precisa estar logado."));
        return;
      }

      // CORREÇÃO: Pegar o ID da fazenda ativa
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(
          RegisterMachineErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }

      int hours = 0;
      if (workingHoursStr.trim().isNotEmpty) {
        hours = int.tryParse(workingHoursStr.trim()) ?? 0;
      }

      final newMachine = MachineModel(
        name: name.trim(),
        model: model.trim(),
        brand: brand.trim(),
        power: power.trim(),
        workingHours: hours,
        warehouseId: warehouseId,
        farmId:
            activeFarmId, // CORREÇÃO: Agora garantido com a variável correta
        isMotorized: isMotorized,
        imageUrl: null,
      );

      await _machineService.createMachine(newMachine, imageFile);
      _changeState(RegisterMachineSuccessState());
    } catch (e) {
      _changeState(RegisterMachineErrorState("Erro ao salvar máquina."));
    }
  }
}
