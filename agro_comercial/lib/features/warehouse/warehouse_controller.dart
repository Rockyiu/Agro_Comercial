import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';

import 'warehouse_state.dart';

class WarehouseController extends ChangeNotifier {
  final WarehouseService _warehouseService;

  WarehouseController(this._warehouseService);

  WarehouseState _state = WarehouseInitialState();
  WarehouseState get state => _state;

  void _changeState(WarehouseState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> loadWarehouseData() async {
    _changeState(WarehouseLoadingState());

    try {
      final user = FirebaseAuth.instance.currentUser;

      // MUDANÇA AQUI: Retiramos o fallback e exigimos o usuário logado
      if (user == null) {
        _changeState(
          WarehouseErrorState("Sessão expirada. Faça o login novamente."),
        );
        return;
      }

      final String uid = user.uid;

      // Busca os armazéns reais no Firebase
      List<WarehouseModel> myWarehouses = await _warehouseService.getWarehouses(
        uid,
      );
      List<MachineModel> myMachines = [];

      _changeState(
        WarehouseSuccessState(warehouses: myWarehouses, machines: myMachines),
      );
    } catch (e) {
      _changeState(
        WarehouseErrorState("Erro ao carregar o armazém: ${e.toString()}"),
      );
    }
  }
}
