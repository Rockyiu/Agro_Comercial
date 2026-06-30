import 'package:flutter/material.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/employee_service/employee_service.dart';
import 'package:agro_comercial/locator.dart'; // ADICIONADO
import 'package:agro_comercial/features/farm/farm_controller.dart'; // ADICIONADO
import 'employee_state.dart';

class EmployeeController extends ChangeNotifier {
  final EmployeeService _employeeService;

  EmployeeController(this._employeeService);

  EmployeeState _state = EmployeeInitialState();
  EmployeeState get state => _state;

  Future<void> loadEmployees() async {
    _state = EmployeeLoadingState();
    notifyListeners();
    try {
      // CORREÇÃO: Busca apenas os funcionários da fazenda ativa
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;

      if (activeFarmId != null) {
        final employeesList = await _employeeService.getEmployees(activeFarmId);
        _state = EmployeeSuccessState(employeesList);
      } else {
        _state = EmployeeErrorState("Nenhuma fazenda ativa selecionada.");
      }
    } catch (e) {
      _state = EmployeeErrorState("Erro ao carregar funcionários.");
    }
    notifyListeners();
  }

  Future<void> registerEmployee(String name, String cpf) async {
    _state = EmployeeLoadingState();
    notifyListeners();
    try {
      // CORREÇÃO: Registra o funcionário na fazenda ativa em vez do UID do admin
      final activeFarmId = locator.get<FarmController>().selectedFarm?.id;

      if (activeFarmId != null) {
        // Atenção: O seu inviteEmployee no EmployeeService vai precisar aceitar esse farmId
        await _employeeService.inviteEmployee(name, cpf, activeFarmId);
      }
      await loadEmployees();
    } catch (e) {
      _state = EmployeeErrorState("Erro ao autorizar funcionário.");
      notifyListeners();
    }
  }

  Future<void> deleteSingleEmployee(UserModel employee) async {
    _state = EmployeeLoadingState();
    notifyListeners();
    try {
      await _employeeService.removeEmployeeAccess(employee);
      await loadEmployees();
    } catch (e) {
      _state = EmployeeErrorState("Erro ao revogar acesso.");
      notifyListeners();
    }
  }

  Future<void> deleteSelectedEmployees(List<UserModel> employees) async {
    _state = EmployeeLoadingState();
    notifyListeners();
    try {
      await _employeeService.removeMultipleEmployees(employees);
      await loadEmployees();
    } catch (e) {
      _state = EmployeeErrorState("Erro ao remover lote.");
      notifyListeners();
    }
  }
}
