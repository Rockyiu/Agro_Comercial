import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_page.dart'; // <-- IMPORT NOVO AQUI
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

  @override
  void initState() {
    super.initState();
    _controller.loadWarehouseData();
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (state is WarehouseSuccessState) {
            if (state.warehouses.isEmpty) {
              return _buildEmptyState();
            }
            return _buildFilledState(state);
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Para registrar tratores ou produtos, você precisa criar um armazém primeiro.',
              style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
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

  // --- NOVA LISTA VERTICAL BASEADA NA SUA IMAGEM ---
  Widget _buildFilledState(WarehouseSuccessState state) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: 24.0,
        left: 16.0,
        right: 16.0,
        bottom: 80.0,
      ), // Margem extra no bottom pelo botão flutuante
      itemCount: state.warehouses.length,
      itemBuilder: (context, index) {
        final warehouse = state.warehouses[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              // Navega para a tela de detalhes passando o armazém clicado!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      WarehouseDetailsPage(warehouse: warehouse),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Ícone na esquerda com fundo clarinho
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenlightOne.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warehouse_outlined,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Textos no meio
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
                          'Toque para ver o estoque',
                          style: AppTextStyles.smallText.copyWith(
                            color: AppColors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botãozinho estilo "Pay" na direita
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenlightOne.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Abrir',
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
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
