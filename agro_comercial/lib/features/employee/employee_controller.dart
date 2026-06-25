import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/employee_service/employee_service.dart';
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final employeesList = await _employeeService.getEmployees(user.uid);
        _state = EmployeeSuccessState(employeesList);
      } else {
        _state = EmployeeErrorState("Usuário não logado.");
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _employeeService.inviteEmployee(name, cpf, user.uid);
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
