import 'package:flutter/material.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/selection_action_bar.dart';
import 'package:agro_comercial/common/utils/formatters.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/locator.dart';

import 'cost_controller.dart';
import 'cost_state.dart';
import 'cost_details_page.dart';
import 'register_cost_page.dart';

class CostPage extends StatefulWidget {
  // false quando a tela é exibida como aba de outra (ex: Home do colaborador),
  // que já tem a própria barra de título
  final bool showAppBar;

  const CostPage({super.key, this.showAppBar = true});

  @override
  State<CostPage> createState() => _CostPageState();
}

class _CostPageState extends State<CostPage> {
  final _costController = locator.get<CostController>();

  // Controle de Seleção Multipla
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _costController.loadCosts();
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

  Future<void> _showDeleteMultipleDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Selecionados",
      message:
          "Tem certeza que deseja excluir os ${selectedIds.length} item(ns) selecionado(s)?",
    );
    if (!confirmed || !mounted) return;
    _costController.deleteSelectedCosts(selectedIds.toList());
    setState(() => selectedIds.clear());
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                "Gestão de Custos",
                style: AppTextStyles.midText20.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.greenlightOne,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: ListenableBuilder(
        listenable: _costController,
        builder: (context, child) {
          final state = _costController.state;

          // CORREÇÃO AQUI: Adição das chaves { } nos blocos IF
          if (state is CostLoadingState) {
            return const Center(child: CustomCircularProgressIndicator());
          }
          if (state is CostErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (_costController.allCosts.isEmpty) {
            return Center(
              child: Text(
                "Nenhum custo lançado.",
                style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
              ),
            );
          }

          return Column(
            children: [
              // HEADER DE EXCLUSÃO MÚLTIPLA
              if (selectedIds.isNotEmpty)
                SelectionActionBar(
                  label: "${selectedIds.length} item(ns) selecionado(s)",
                  margin: const EdgeInsets.all(16),
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  onClear: () => setState(() => selectedIds.clear()),
                  onDelete: _showDeleteMultipleDialog,
                ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.greenlightOne,
                  onRefresh: () => _costController.loadCosts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _costController.allCosts.length,
                    itemBuilder: (context, index) {
                      final cost = _costController.allCosts[index];
                      Color typeColor = cost.type == 'Fixo'
                          ? Colors.blueAccent
                          : Colors.orangeAccent;
                      final isSelected = selectedIds.contains(cost.id);

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onLongPress: () {
                          if (cost.id != null) _toggleSelection(cost.id!);
                        },
                        onTap: () async {
                          if (selectedIds.isNotEmpty && cost.id != null) {
                            _toggleSelection(cost.id!);
                          } else {
                            // ABRE A TELA DE DETALHES E ESPERA VOLTAR PARA RECARREGAR
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CostDetailsPage(cost: cost),
                              ),
                            );
                            _costController.loadCosts();
                          }
                        },
                        child: Card(
                          elevation: isSelected ? 0 : 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.greenlightOne
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          color: isSelected
                              ? AppColors.greenlightOne.withValues(alpha: 0.05)
                              : Colors.white,
                          child: ClipPath(
                            clipper: ShapeBorderClipper(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(color: typeColor, width: 6),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: isSelected
                                    ? const CircleAvatar(
                                        backgroundColor:
                                            AppColors.greenlightOne,
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                                title: Text(
                                  cost.category,
                                  style: AppTextStyles.smallText.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tipo: ${cost.type}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      Formatters.date(cost.dateTimestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  Formatters.currency(cost.value),
                                  style: AppTextStyles.smallText.copyWith(
                                    color: AppColors.greenlightOne,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.greenlightOne,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterCostPage()),
          );
          _costController.loadCosts();
        },
      ),
    );
  }
}
