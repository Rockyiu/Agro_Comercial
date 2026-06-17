import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'field_operation_controller.dart';
import 'field_operation_state.dart';

class FieldOperationPage extends StatefulWidget {
  const FieldOperationPage({super.key});

  @override
  State<FieldOperationPage> createState() => _FieldOperationPageState();
}

class _FieldOperationPageState extends State<FieldOperationPage> {
  final _controller = locator.get<FieldOperationController>();
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _controller.loadOperationsData();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  void _showDeleteMultipleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Excluir Selecionados",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        content: Text(
          "Deseja apagar as ${selectedIds.length} operações de campo?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteSelectedOperations(selectedIds.toList());
              setState(() => selectedIds.clear());
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
      // ADICIONADO: A barra superior com o botão de voltar!
      appBar: AppBar(
        title: Text(
          "Vistorias e Aplicações",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;

          if (state is FieldOperationLoadingState ||
              state is FieldOperationInitialState) {
            return const Center(child: CustomCircularProgressIndicator());
          }
          if (state is FieldOperationErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (state is FieldOperationSuccessState) {
            if (state.operations.isEmpty) {
              return Center(
                child: Text(
                  "Nenhuma vistoria registrada.",
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.lightkGrey,
                  ),
                ),
              );
            }
            return Column(
              children: [
                if (selectedIds.isNotEmpty)
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
                          "${selectedIds.length} selecionada(s)",
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
                                  setState(() => selectedIds.clear()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _showDeleteMultipleDialog,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.operations.length,
                    itemBuilder: (context, index) {
                      final op = state.operations[index];
                      final isSelected = selectedIds.contains(op.id);

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
                          onLongPress: () => _toggleSelection(op.id!),
                          onTap: () async {
                            if (selectedIds.isNotEmpty) {
                              _toggleSelection(op.id!);
                            } else {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FieldOperationDetailsPage(operation: op),
                                ),
                              );
                              _controller.loadOperationsData();
                            }
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.greenlightOne
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                op.type == 'Vistoria'
                                    ? Icons.search
                                    : Icons.opacity,
                                color: AppColors.greenlightOne,
                              ),
                            ),
                            title: Text(
                              "${op.type} - ${op.plotName}",
                              style: AppTextStyles.inputText.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              op.observations ??
                                  (op.productName != null
                                      ? "Insumo: ${op.productName}"
                                      : "Talhão em análise"),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.lightkGrey,
                            ),
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
              builder: (context) => const RegisterFieldOperationPage(),
            ),
          );
          _controller.loadOperationsData();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
