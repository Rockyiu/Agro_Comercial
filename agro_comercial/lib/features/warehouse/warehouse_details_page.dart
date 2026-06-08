import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/features/edit_machine/edit_machine_page.dart';
import 'package:agro_comercial/features/edit_product/edit_product_page.dart';
import 'package:agro_comercial/features/edit_warehouse/edit_warehouse_page.dart';
import 'package:agro_comercial/features/register_machine/register_machine_page.dart';
import 'package:agro_comercial/features/register_product/register_product_page.dart'; // IMPORTANTE
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

  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _controller.loadInventory(widget.warehouse.id!);
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

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.iceWhite,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'O que deseja adicionar neste armazém?',
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.greenlightOne,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.agriculture,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text(
                    'Cadastrar Máquina',
                    style: AppTextStyles.inputText,
                  ),
                  subtitle: Text(
                    'Trator, colhedora, implementos',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterMachinePage(),
                      ),
                    );
                    // CORRIGIDO: Alterado de loadMachines para loadInventory
                    _controller.loadInventory(widget.warehouse.id!);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.inventory,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text(
                    'Cadastrar Produto',
                    style: AppTextStyles.inputText,
                  ),
                  subtitle: Text(
                    'Insumos, sementes, agrotóxicos',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  // RESOLVIDO: O seu bloco onTap integrado com sucesso aqui!
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterProductPage(
                          initialWarehouse: widget.warehouse,
                        ),
                      ),
                    );
                    _controller.loadInventory(widget.warehouse.id!);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
          "Tem certeza que deseja excluir os ${selectedIds.length} item(ns) selecionado(s)?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteSelectedItems(
                selectedIds.toList(),
                widget.warehouse.id!,
              );
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
            Row(
              children: [
                _buildFilterChip('Tudo'),
                const SizedBox(width: 8),
                _buildFilterChip('Máquinas'),
                const SizedBox(width: 8),
                _buildFilterChip('Produtos'),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedIds.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.greenlightOne.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${selectedIds.length} item(ns) selecionado(s)",
                      style: AppTextStyles.inputText.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.grey),
                          onPressed: () => setState(() => selectedIds.clear()),
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
                    List<dynamic> combinedList = [];

                    if (_selectedFilter == 'Tudo' ||
                        _selectedFilter == 'Máquinas') {
                      combinedList.addAll(state.machines);
                    }
                    if (_selectedFilter == 'Tudo' ||
                        _selectedFilter == 'Produtos') {
                      combinedList.addAll(state.products);
                    }

                    if (combinedList.isEmpty) {
                      return Center(
                        child: Text(
                          'Nenhum item encontrado para este filtro.',
                          style: AppTextStyles.smallText.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: combinedList.length,
                      itemBuilder: (context, index) {
                        final item = combinedList[index];
                        if (item is MachineModel) {
                          return _buildMachineCard(item);
                        } else {
                          return _buildProductCard(item);
                        }
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.greenlightOne,
        onPressed: _showAddMenu,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final isSelected = selectedIds.contains(product.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: () => _toggleSelection(product.id!),
      onTap: () async {
        if (selectedIds.isNotEmpty) {
          _toggleSelection(product.id!);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProductPage(product: product),
            ),
          );
          _controller.loadInventory(widget.warehouse.id!);
        }
      },
      child: Card(
        elevation: isSelected ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.greenlightOne : Colors.transparent,
            width: 2,
          ),
        ),
        color: isSelected
            ? AppColors.greenlightOne.withOpacity(0.05)
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.greenlightOne
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.inventory_2,
                  size: 32,
                  color: isSelected ? Colors.white : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenlightOne,
                      ),
                    ),
                    Text(
                      "${product.brand} • ${product.category}",
                      style: AppTextStyles.smallText.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightkGrey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Qtd: ${product.quantity} ${product.unit}",
                        style: AppTextStyles.smallText.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
  }

  Widget _buildMachineCard(MachineModel machine) {
    final isSelected = selectedIds.contains(machine.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onLongPress: () => _toggleSelection(machine.id!),
      onTap: () async {
        if (selectedIds.isNotEmpty) {
          _toggleSelection(machine.id!);
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditMachinePage(machine: machine),
            ),
          );
          // CORRIGIDO: Alterado de loadMachines para loadInventory
          _controller.loadInventory(widget.warehouse.id!);
        }
      },
      child: Card(
        elevation: isSelected ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.greenlightOne : Colors.transparent,
            width: 2,
          ),
        ),
        color: isSelected
            ? AppColors.greenlightOne.withOpacity(0.05)
            : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.greenlightOne
                      : AppColors.greenlightOne.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.greenlightOne.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.agriculture,
                  size: 40,
                  color: isSelected ? Colors.white : AppColors.greenlightOne,
                ),
              ),
              const SizedBox(width: 16),
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
                      machine.brand + " • " + machine.model,
                      style: AppTextStyles.smallText.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoTag(
                          Icons.bolt,
                          "${machine.power} cv",
                          isSelected,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoTag(
                          Icons.timer_outlined,
                          "${machine.workingHours}h",
                          isSelected,
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

  Widget _buildInfoTag(IconData icon, String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : AppColors.lightkGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? AppColors.greenlightOne : AppColors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.smallText.copyWith(
              fontSize: 11,
              color: isSelected ? AppColors.greenlightOne : AppColors.grey,
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
            selectedIds.clear();
          });
        }
      },
    );
  }
}
