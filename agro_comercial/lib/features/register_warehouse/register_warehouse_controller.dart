import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'register_warehouse_state.dart';

class RegisterWarehouseController extends ChangeNotifier {
  final WarehouseService _warehouseService;

  RegisterWarehouseController(this._warehouseService);

  RegisterWarehouseState _state = RegisterWarehouseInitialState();
  RegisterWarehouseState get state => _state;

  void _changeState(RegisterWarehouseState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> saveWarehouse({required String name}) async {
    _changeState(RegisterWarehouseLoadingState());

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _changeState(
          RegisterWarehouseErrorState("Você precisa estar logado para salvar."),
        );
        return;
      }

      // CORREÇÃO: Pegando o ID da Fazenda Ativa
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;

      if (activeFarmId == null) {
        _changeState(
          RegisterWarehouseErrorState("Nenhuma fazenda ativa selecionada."),
        );
        return;
      }

      // Busca os armazéns apenas da fazenda ativa
      final existingWarehouses = await _warehouseService.getWarehouses(
        activeFarmId,
      );

      final bool alreadyExists = existingWarehouses.any(
        (w) => w.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );

      if (alreadyExists) {
        _changeState(
          RegisterWarehouseErrorState(
            "Você já possui um armazém com este nome nesta fazenda.",
          ),
        );
        return;
      }

      // Salvando com o ID DA FAZENDA (activeFarmId)
      final newWarehouse = WarehouseModel(
        name: name.trim(),
        farmId: activeFarmId,
      );

      await _warehouseService.createWarehouse(newWarehouse);

      _changeState(RegisterWarehouseSuccessState());
    } catch (e) {
      _changeState(
        RegisterWarehouseErrorState("Erro ao salvar armazém. Tente novamente."),
      );
    }
  }
}
