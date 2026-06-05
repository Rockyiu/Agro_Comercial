import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
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

      // MUDANÇA AQUI: Retiramos o fallback. Se não tiver usuário, barra a operação!
      if (user == null) {
        _changeState(
          RegisterWarehouseErrorState("Você precisa estar logado para salvar."),
        );
        return;
      }

      final String uid = user.uid;

      // 1. Busca os armazéns que o usuário já tem cadastrados
      final existingWarehouses = await _warehouseService.getWarehouses(uid);

      // 2. Verifica se algum tem o nome EXATAMENTE igual (ignorando espaços e maiúsculas/minúsculas)
      final bool alreadyExists = existingWarehouses.any(
        (w) => w.name.trim().toLowerCase() == name.trim().toLowerCase(),
      );

      if (alreadyExists) {
        _changeState(
          RegisterWarehouseErrorState(
            "Você já possui um armazém com este nome.",
          ),
        );
        return;
      }

      // 3. Se for um nome novo, cria o modelo
      final newWarehouse = WarehouseModel(name: name.trim(), farmId: uid);

      await _warehouseService.createWarehouse(newWarehouse);

      _changeState(RegisterWarehouseSuccessState());
    } catch (e) {
      _changeState(
        RegisterWarehouseErrorState("Erro ao salvar armazém. Tente novamente."),
      );
    }
  }
}
