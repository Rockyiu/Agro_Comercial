import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/selection_action_bar.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'employee_controller.dart';
import 'employee_state.dart';
import 'register_employee_page.dart';

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final _controller = locator.get<EmployeeController>();
  Set<UserModel> selectedEmployees = {};

  @override
  void initState() {
    super.initState();
    _controller.loadEmployees();
  }

  void _toggleSelection(UserModel emp) {
    setState(() {
      if (selectedEmployees.any((e) => e.id == emp.id)) {
        selectedEmployees.removeWhere((e) => e.id == emp.id);
      } else {
        selectedEmployees.add(emp);
      }
    });
  }

  Future<void> _showDeleteDialog({UserModel? singleEmp}) async {
    final confirmed = await showConfirmDialog(
      context,
      title: singleEmp != null ? "Excluir Funcionário" : "Excluir Selecionados",
      message: singleEmp != null
          ? "Deseja revogar o acesso de ${singleEmp.name} ao sistema?"
          : "Deseja revogar o acesso dos ${selectedEmployees.length} funcionários?",
    );
    if (!confirmed || !mounted) return;
    if (singleEmp != null) {
      _controller.deleteSingleEmployee(singleEmp);
    } else {
      _controller.deleteSelectedEmployees(selectedEmployees.toList());
      setState(() => selectedEmployees.clear());
    }
  }

  Future<void> _setHarvestPermission(UserModel emp, bool allowed) async {
    final ok = await _controller.setHarvestPermission(emp, allowed);
    if (!mounted) return;
    if (!ok) {
      context.showErrorSnackBar("Não foi possível alterar a permissão.");
      return;
    }
    context.showSuccessSnackBar(
      allowed
          ? "${emp.name} agora pode registrar Produção / Colheita."
          : "Produção / Colheita bloqueada para ${emp.name}.",
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Minha Equipe",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;

          if (state is EmployeeLoadingState || state is EmployeeInitialState) {
            return const Center(child: CustomCircularProgressIndicator());
          }
          if (state is EmployeeErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.danger),
              ),
            );
          }

          if (state is EmployeeSuccessState) {
            if (state.employees.isEmpty) {
              return Center(
                child: Text(
                  "Nenhum funcionário cadastrado.",
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.lightkGrey,
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (selectedEmployees.isNotEmpty)
                  SelectionActionBar(
                    label: "${selectedEmployees.length} selecionado(s)",
                    onClear: () => setState(() => selectedEmployees.clear()),
                    onDelete: _showDeleteDialog,
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.employees.length,
                    itemBuilder: (context, index) {
                      final emp = state.employees[index];
                      final isSelected = selectedEmployees.any(
                        (e) => e.id == emp.id,
                      );

                      return Card(
                        elevation: isSelected ? 0 : 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isSelected
                            ? AppColors.greenlightOne.withValues(alpha: 0.05)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.greenlightOne
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onLongPress: () => _toggleSelection(emp),
                          onTap: () {
                            if (selectedEmployees.isNotEmpty) {
                              _toggleSelection(emp);
                            }
                          },
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.greenlightOne
                                      .withValues(alpha: 0.1),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.greenlightOne,
                                  ),
                                ),
                                title: Text(
                                  emp.name ?? '',
                                  style: AppTextStyles.inputText.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  "CPF: ${emp.cpf ?? 'Não informado'}",
                                ),
                                trailing: selectedEmployees.isEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.danger,
                                        ),
                                        onPressed: () =>
                                            _showDeleteDialog(singleEmp: emp),
                                      )
                                    : null,
                              ),
                              // Permissões que o produtor pode liberar
                              SwitchListTile(
                                dense: true,
                                secondary: const Icon(
                                  Icons.grass_rounded,
                                  color: AppColors.greenlightOne,
                                ),
                                title: const Text(
                                  "Pode registrar Produção / Colheita",
                                ),
                                activeThumbColor: AppColors.greenlightOne,
                                value: emp.canRegisterHarvest,
                                onChanged: selectedEmployees.isEmpty
                                    ? (v) => _setHarvestPermission(emp, v)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterEmployeePage(),
            ),
          );
          _controller.loadEmployees();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
