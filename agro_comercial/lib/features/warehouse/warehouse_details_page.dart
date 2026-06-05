import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/features/edit_machine/edit_machine_page.dart';
import 'package:agro_comercial/features/edit_warehouse/edit_warehouse_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

class WarehouseDetailsPage extends StatefulWidget {
  final WarehouseModel warehouse;

  const WarehouseDetailsPage({super.key, required this.warehouse});

  @override
  State<WarehouseDetailsPage> createState() => _WarehouseDetailsPageState();
}

class _WarehouseDetailsPageState extends State<WarehouseDetailsPage> {
  String _selectedFilter = 'Tudo';
  final _controller = locator.get<WarehouseDetailsController>();

  @override
  void initState() {
    super.initState();
    // Pede pro controlador buscar as máquinas usando o ID deste armazém!
    _controller.loadMachines(widget.warehouse.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.greenlightOne,
        elevation: 0,
        title: Text(
          widget.warehouse.name,
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditWarehousePage(warehouse: widget.warehouse),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estoque',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
            const SizedBox(height: 12),

            // Filtros
            Row(
              children: [
                _buildFilterChip('Tudo'),
                const SizedBox(width: 8),
                _buildFilterChip('Máquinas'),
                const SizedBox(width: 8),
                _buildFilterChip('Produtos'),
              ],
            ),
            const SizedBox(height: 24),

            // Lista Dinâmica conectada ao Controlador
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  final state = _controller.state;

                  if (state is WarehouseDetailsLoadingState ||
                      state is WarehouseDetailsInitialState) {
                    return const Center(
                      child: CustomCircularProgressIndicator(),
                    );
                  }

                  if (state is WarehouseDetailsErrorState) {
                    return Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state is WarehouseDetailsSuccessState) {
                    // Filtra a lista dependendo do botão escolhido
                    List<MachineModel> displayList = state.machines;
                    if (_selectedFilter == 'Produtos') {
                      displayList = []; // Ainda não temos produtos
                    }

                    if (displayList.isEmpty) {
                      return Center(
                        child: Text(
                          'O estoque deste armazém está vazio para este filtro.',
                          style: AppTextStyles.smallText.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        return _buildMachineCard(displayList[index]);
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMachineCard(MachineModel machine) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        // Abre a tela de edição
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditMachinePage(machine: machine),
          ),
        );

        // Quando voltar da edição, força a lista a atualizar para mostrar os dados novos!
        _controller.loadMachines(widget.warehouse.id!);
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Círculo da foto da máquina
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: AppColors.greenlightOne.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.greenlightOne.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.agriculture,
                  size: 40,
                  color: AppColors.greenlightOne,
                ),
              ),
              const SizedBox(width: 16),

              // Informações da Máquina
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenlightOne,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${machine.brand} • ${machine.model}",
                      style: AppTextStyles.smallText.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tags de Potência e Horas
                    Row(
                      children: [
                        // Colocando o 'cv' de forma visual aqui!
                        _buildInfoTag(Icons.bolt, "${machine.power} cv"),
                        const SizedBox(width: 8),
                        _buildInfoTag(
                          Icons.timer_outlined,
                          "${machine.workingHours}h",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightkGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.smallText.copyWith(
              fontSize: 11,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.greenlightOne.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.greenlightOne : AppColors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }
}
