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

  void _showDeleteDialog({UserModel? singleEmp}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          singleEmp != null ? "Excluir Funcionário" : "Excluir Selecionados",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        content: Text(
          singleEmp != null
              ? "Deseja revogar o acesso de ${singleEmp.name} ao sistema?"
              : "Deseja revogar o acesso dos ${selectedEmployees.length} funcionários?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (singleEmp != null) {
                _controller.deleteSingleEmployee(singleEmp);
              } else {
                _controller.deleteSelectedEmployees(selectedEmployees.toList());
                setState(() => selectedEmployees.clear());
              }
            },
            child: const Text(
              "Sim, excluir",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                style: const TextStyle(color: Colors.red),
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
                  Container(
                    color: AppColors.greenlightOne.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedEmployees.length} selecionado(s)",
                          style: AppTextStyles.inputText.copyWith(
                            color: AppColors.greenlightOne,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.grey,
                              ),
                              onPressed: () =>
                                  setState(() => selectedEmployees.clear()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                            if (selectedEmployees.isNotEmpty)
                              _toggleSelection(emp);
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.greenlightOne
                                  .withValues(alpha: 0.1),
                              child: const Icon(
                                Icons.person,
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
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(singleEmp: emp),
                                  )
                                : null,
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
        backgroundColor: AppColors.greenlightOne,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegisterEmployeePage(),
            ),
          );
          _controller.loadEmployees();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
