import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/services/employee_service/employee_service.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'collaborator_home_state.dart';

class CollaboratorHomeController extends SafeChangeNotifier {
  final OperationService _operationService;
  final FieldOperationService _fieldOperationService;
  final FarmController _farmController;
  final EmployeeService _employeeService;

  CollaboratorHomeController(
    this._operationService,
    this._fieldOperationService,
    this._farmController,
    this._employeeService,
  );

  // Liberado pelo produtor em "Minha Equipe" para registrar Produção/Colheita
  bool canRegisterHarvest = false;

  CollaboratorHomeState _state = CollaboratorHomeInitialState();
  CollaboratorHomeState get state => _state;

  void _changeState(CollaboratorHomeState newState) {
    _state = newState;
    notifyListeners();
  }

  // Carrega somente as atividades (operações, vistorias e aplicações)
  // registradas pelo colaborador logado na fazenda à qual ele está vinculado.
  // [reloadFarm] força buscar novamente a fazenda vinculada (ex: ao abrir a
  // tela), evitando reaproveitar a fazenda de outro usuário que usou o app antes.
  // [showLoading] = false mantém a lista na tela enquanto atualiza
  // (usado no "puxar para atualizar")
  Future<void> loadActivities({
    bool reloadFarm = false,
    bool showLoading = true,
  }) async {
    if (showLoading) _changeState(CollaboratorHomeLoadingState());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _changeState(CollaboratorHomeErrorState("Usuário não autenticado."));
        return;
      }

      if (reloadFarm || _farmController.selectedFarm == null) {
        await _farmController.loadCollaboratorFarm();
      }

      final farmId = _farmController.selectedFarm?.id;
      if (farmId == null) {
        canRegisterHarvest = false;
        _changeState(CollaboratorHomeNoFarmState());
        return;
      }

      // Busca as listas e a permissão de colheita em paralelo
      final (operations, fieldOperations, harvestAllowed) = await (
        _operationService.getOperationsByUser(farmId, user.uid),
        _fieldOperationService.getFieldOperationsByUser(farmId, user.uid),
        _employeeService.hasHarvestPermission(user.uid),
      ).wait;
      canRegisterHarvest = harvestAllowed;

      _changeState(
        CollaboratorHomeSuccessState(
          operations: operations,
          fieldOperations: fieldOperations,
        ),
      );
    } catch (e) {
      debugPrint("Erro ao carregar atividades do colaborador: $e");
      _changeState(
        CollaboratorHomeErrorState("Erro ao carregar suas atividades."),
      );
    }
  }
}
