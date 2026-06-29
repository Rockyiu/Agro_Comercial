import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'warehouse_controller.dart';
import 'warehouse_state.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final _controller = locator.get<WarehouseController>();

  // Lista que guarda o ID dos armazéns selecionados
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Garante que o carregamento só inicie após a tela estar 100% desenhada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller
          .loadWarehouseData(); // ou loadOperationsData() nas outras páginas
    });
  }

  // Função que seleciona ou desmarca um item
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
          "Tem certeza que deseja excluir ${selectedIds.length} armazém(ns)? Todas as máquinas neles também serão apagadas!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteSelectedWarehouses(selectedIds.toList());
              setState(
                () => selectedIds.clear(),
              ); // Limpa a seleção após excluir
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;

          if (state is WarehouseLoadingState ||
              state is WarehouseInitialState) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          if (state is WarehouseErrorState) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is WarehouseSuccessState) {
            if (state.warehouses.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children: [
                // BARRA DE SELEÇÃO: Só aparece se houver itens selecionados!
                if (selectedIds.isNotEmpty)
                  Container(
                    color: AppColors.greenlightOne.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${selectedIds.length} selecionado(s)",
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
                              onPressed: () => setState(
                                () => selectedIds.clear(),
                              ), // Cancela a seleção
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  _showDeleteMultipleDialog, // Chama a exclusão
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // LISTA DE ARMAZÉNS
                Expanded(child: _buildFilledState(state)),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.warehouse_outlined,
              size: 80,
              color: AppColors.lightkGrey,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum armazém encontrado',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Cadastrar Armazém',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterWarehousePage(),
                  ),
                );
                _controller.loadWarehouseData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilledState(WarehouseSuccessState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: 80.0,
      ),
      itemCount: state.warehouses.length,
      itemBuilder: (context, index) {
        final warehouse = state.warehouses[index];
        final isSelected = selectedIds.contains(
          warehouse.id,
        ); // Verifica se este galpão está selecionado

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onLongPress: () => _toggleSelection(
              warehouse.id!,
            ), // CLIQUE LONGO: Ativa a seleção
            onTap: () {
              // Se tiver selecionando, o clique normal também seleciona. Se não, abre a tela!
              if (selectedIds.isNotEmpty) {
                _toggleSelection(warehouse.id!);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WarehouseDetailsPage(warehouse: warehouse),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // MUDANÇA DE COR VISUAL: Fica verdinho se estiver selecionado
                color: isSelected
                    ? AppColors.greenlightOne.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.greenlightOne
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // ÍCONE DINÂMICO: Mostra o galpão ou um 'Check' se selecionado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.greenlightOne
                          : AppColors.greenlightOne.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.warehouse_outlined,
                      color: isSelected
                          ? Colors.white
                          : AppColors.greenlightOne,
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warehouse.name,
                          style: AppTextStyles.inputText.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque longo para selecionar',
                          style: AppTextStyles.smallText.copyWith(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
