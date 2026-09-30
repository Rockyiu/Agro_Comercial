import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/services/employee_service/employee_service.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'home_state.dart';

class HomeController extends SafeChangeNotifier {
  final OperationService _operationService;
  final FieldOperationService _fieldOperationService;
  final EmployeeService _employeeService;
  final FarmController _farmController;

  HomeController(
    this._operationService,
    this._fieldOperationService,
    this._employeeService,
    this._farmController,
  );

  HomeState _state = HomeInitialState();
  HomeState get state => _state;

  void _changeState(HomeState newState) {
    _state = newState;
    notifyListeners();
  }

  // Carrega todas as atividades (operações, vistorias e aplicações) da fazenda
  // ativa, registradas pelo produtor ou pela equipe, com o nome de quem registrou.
  // [showLoading] = false mantém a lista na tela enquanto atualiza
  // (usado no "puxar para atualizar")
  Future<void> loadActivities({bool showLoading = true}) async {
    if (showLoading) _changeState(HomeLoadingState());
    try {
      final user = FirebaseAuth.instance.currentUser;
      final farmId = _farmController.selectedFarm?.id;
      if (user == null || farmId == null) {
        _changeState(
          HomeErrorState("Usuário não autenticado ou sem fazenda ativa."),
        );
        return;
      }

      // Busca as duas listas em paralelo
      final (operations, fieldOperations) = await (
        _operationService.getOperations(farmId),
        _fieldOperationService.getFieldOperations(farmId),
      ).wait;

      // Nomes de quem registrou (o próprio produtor aparece como "Você")
      final authorIds = <String>{
        for (final op in operations)
          if (op.createdBy != null) op.createdBy!,
        for (final fOp in fieldOperations)
          if (fOp.createdBy != null) fOp.createdBy!,
      }..remove(user.uid);

      Map<String, String> authorNames = {};
      try {
        authorNames = await _employeeService.getUserNames(authorIds);
      } catch (e) {
        // Sem os nomes a lista ainda aparece, com "Colaborador" como autor
        debugPrint("Erro ao buscar nomes dos autores: $e");
      }

      _changeState(
        HomeSuccessState(
          operations: operations,
          fieldOperations: fieldOperations,
          currentUserId: user.uid,
          authorNames: authorNames,
        ),
      );
    } catch (e) {
      debugPrint("Erro ao carregar atividades da fazenda: $e");
      _changeState(
        HomeErrorState("Erro ao carregar as atividades da fazenda."),
      );
    }
  }
}
