import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/employee_service/employee_service.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'employee_state.dart';

class EmployeeController extends SafeChangeNotifier {
  final EmployeeService _employeeService;
  final FarmController _farmController;

  EmployeeController(this._employeeService, this._farmController);

  EmployeeState _state = EmployeeInitialState();
  EmployeeState get state => _state;

  Future<void> loadEmployees() async {
    _state = EmployeeLoadingState();
    notifyListeners();
    try {
      // Busca apenas os funcionários da fazenda ativa
      final activeFarmId = _farmController.selectedFarm?.id;

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
      // Registra o funcionário na fazenda ativa
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _state = EmployeeErrorState("Nenhuma fazenda ativa selecionada.");
        notifyListeners();
        return;
      }

      await _employeeService.inviteEmployee(name, cpf, activeFarmId);
      await loadEmployees();
    } on EmployeeNotFoundException catch (e) {
      // Mensagem específica (ex: CPF sem cadastro no app) em vez da genérica
      _state = EmployeeErrorState(e.message);
      notifyListeners();
    } catch (e) {
      _state = EmployeeErrorState("Erro ao autorizar funcionário.");
      notifyListeners();
    }
  }

  // Libera/bloqueia Produção/Colheita para o colaborador. A lista é atualizada
  // na hora (sem tela de carregamento) e volta ao valor anterior se falhar.
  // Retorna false em caso de erro, para a tela avisar.
  Future<bool> setHarvestPermission(UserModel employee, bool allowed) async {
    final current = _state;
    if (employee.id == null || current is! EmployeeSuccessState) return false;

    void replace(bool value) {
      _state = EmployeeSuccessState([
        for (final e in (_state as EmployeeSuccessState).employees)
          e.id == employee.id ? e.copyWith(canRegisterHarvest: value) : e,
      ]);
      notifyListeners();
    }

    replace(allowed);
    try {
      await _employeeService.setHarvestPermission(employee.id!, allowed);
      return true;
    } catch (e) {
      if (_state is EmployeeSuccessState) replace(!allowed);
      return false;
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
