import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/selection_action_bar.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/features/edit_machine/edit_machine_page.dart';
import 'package:agro_comercial/features/edit_product/edit_product_page.dart';
import 'package:agro_comercial/features/edit_warehouse/edit_warehouse_page.dart';
import 'package:agro_comercial/features/home/widgets/add_menu_sheet.dart';
import 'package:agro_comercial/features/register_machine/register_machine_page.dart';
import 'package:agro_comercial/features/register_product/register_product_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:flutter/material.dart';

class WarehouseDetailsPage extends StatefulWidget {
  final WarehouseModel warehouse;

  const WarehouseDetailsPage({super.key, required this.warehouse});

  @override
  State<WarehouseDetailsPage> createState() => _WarehouseDetailsPageState();
}

class _WarehouseDetailsPageState extends State<WarehouseDetailsPage> {
  static const _filters = ['Tudo', 'Máquinas', 'Produtos'];

  String _selectedFilter = 'Tudo';
  final _controller = locator.get<WarehouseDetailsController>();

  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    _controller.loadInventory(widget.warehouse);
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

  // Abre a tela e recarrega o estoque ao voltar
  Future<void> _openAndReload(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _controller.loadInventory(widget.warehouse);
  }

  void _showAddMenu() {
    showAddMenuSheet(
      context,
      title: 'Adicionar ao armazém',
      options: [
        AddMenuOption(
          icon: Icons.agriculture_rounded,
          title: 'Cadastrar Máquina',
          subtitle: 'Trator, colhedora, implementos',
          onTap: () => _openAndReload(const RegisterMachinePage()),
        ),
        AddMenuOption(
          icon: Icons.inventory_2_rounded,
          title: 'Cadastrar Produto',
          subtitle: 'Insumos, sementes, defensivos e fertilizantes',
          onTap: () => _openAndReload(
            RegisterProductPage(initialWarehouse: widget.warehouse),
          ),
        ),
      ],
    );
  }

  Future<void> _showDeleteMultipleDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Selecionados",
      message:
          "Tem certeza que deseja excluir os ${selectedIds.length} item(ns) selecionado(s)?",
    );
    if (!confirmed || !mounted) return;
    _controller.deleteSelectedItems(selectedIds.toList(), widget.warehouse);
    setState(() => selectedIds.clear());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.warehouse.name),
        actions: [
          IconButton(
            tooltip: 'Editar armazém',
            icon: const Icon(Icons.edit_rounded),
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
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;

          if (state is WarehouseDetailsLoadingState ||
              state is WarehouseDetailsInitialState) {
            return const CustomCircularProgressIndicator();
          }
          if (state is WarehouseDetailsErrorState) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Algo deu errado',
                message: state.message,
                action: TextButton.icon(
                  onPressed: () => _controller.loadInventory(widget.warehouse),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Tentar novamente'),
                ),
              ),
            );
          }
          if (state is WarehouseDetailsSuccessState) {
            return _buildInventory(state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenu,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
    );
  }

  Widget _buildInventory(WarehouseDetailsSuccessState state) {
    final items = <Object>[
      if (_selectedFilter != 'Produtos') ...state.machines,
      if (_selectedFilter != 'Máquinas') ...state.products,
    ];
    final motorized = state.machines.where((m) => m.isMotorized).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        FadeSlideIn(
          child: PageHero(
            icon: Icons.warehouse_rounded,
            eyebrow: 'Estoque do armazém',
            title: widget.warehouse.name,
            metrics: [
              HeroMetric(
                icon: Icons.agriculture_rounded,
                label: 'Máquinas',
                value: '${state.machines.length}',
              ),
              HeroMetric(
                icon: Icons.speed_rounded,
                label: 'Motorizadas',
                value: '$motorized',
              ),
              HeroMetric(
                icon: Icons.inventory_2_rounded,
                label: 'Produtos',
                value: '${state.products.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _filters)
              ChoiceChip(
                label: Text(switch (filter) {
                  'Máquinas' => 'Máquinas (${state.machines.length})',
                  'Produtos' => 'Produtos (${state.products.length})',
                  _ => 'Tudo',
                }),
                avatar: Icon(switch (filter) {
                  'Máquinas' => Icons.agriculture_rounded,
                  'Produtos' => Icons.inventory_2_rounded,
                  _ => Icons.apps_rounded,
                }, size: 18),
                showCheckmark: false,
                selected: _selectedFilter == filter,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _selectedFilter = filter;
                    selectedIds.clear();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: selectedIds.isEmpty
              ? const SizedBox(width: double.infinity)
              : SelectionActionBar(
                  label: "${selectedIds.length} item(ns) selecionado(s)",
                  margin: const EdgeInsets.only(bottom: 12),
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  onClear: () => setState(() => selectedIds.clear()),
                  onDelete: _showDeleteMultipleDialog,
                ),
        ),
        if (items.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_rounded,
            title: 'Nada por aqui ainda',
            message:
                'Nenhum item encontrado para este filtro. Toque em Adicionar para cadastrar máquinas ou produtos.',
          )
        else
          for (var i = 0; i < items.length; i++)
            FadeSlideIn(
              // A key refaz a entrada animada ao trocar o filtro
              key: ValueKey('$_selectedFilter-$i'),
              index: i,
              child: switch (items[i]) {
                final MachineModel machine => _buildMachineCard(machine),
                final ProductModel product => _buildProductCard(product),
                _ => const SizedBox.shrink(),
              },
            ),
      ],
    );
  }

  void _onItemTap(String id, Widget editPage) {
    if (selectedIds.isNotEmpty) {
      _toggleSelection(id);
    } else {
      _openAndReload(editPage);
    }
  }

  Widget _buildProductCard(ProductModel product) {
    final isSelected = selectedIds.contains(product.id);
    final details = [
      product.brand,
      product.category,
    ].where((t) => t.trim().isNotEmpty).join(' • ');

    return SurfaceCard(
      selected: isSelected,
      onLongPress: () => _toggleSelection(product.id!),
      onTap: () => _onItemTap(product.id!, EditProductPage(product: product)),
      child: Row(
        children: [
          _ItemBadge(
            selected: isSelected,
            icon: Icons.inventory_2_rounded,
            color: AppColors.harvestDark,
            background: AppColors.harvestSoft,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemTitle(product.name),
                if (details.isNotEmpty) _ItemSubtitle(details),
                const SizedBox(height: 8),
                StatusChip(
                  icon: Icons.scale_rounded,
                  label:
                      "${Formatters.decimal(product.quantity)} ${product.unit}",
                  color: AppColors.harvestDark,
                  background: AppColors.harvestSoft,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }

  Widget _buildMachineCard(MachineModel machine) {
    final isSelected = selectedIds.contains(machine.id);
    final details = [
      machine.brand,
      machine.model,
    ].where((t) => t.trim().isNotEmpty).join(' • ');

    return SurfaceCard(
      selected: isSelected,
      onLongPress: () => _toggleSelection(machine.id!),
      onTap: () => _onItemTap(machine.id!, EditMachinePage(machine: machine)),
      child: Row(
        children: [
          _ItemBadge(
            selected: isSelected,
            icon: machine.isMotorized
                ? Icons.agriculture_rounded
                : Icons.construction_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemTitle(machine.name),
                if (details.isNotEmpty) _ItemSubtitle(details),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (machine.power.trim().isNotEmpty)
                      StatusChip(
                        icon: Icons.bolt_rounded,
                        label: machine.powerLabel,
                        color: AppColors.primary,
                        background: AppColors.primarySoft,
                      ),
                    if (machine.isMotorized)
                      StatusChip(
                        icon: Icons.timer_outlined,
                        label: Formatters.hours(machine.workingHours),
                        color: AppColors.sky,
                        background: AppColors.skySoft,
                      )
                    else
                      const StatusChip(
                        icon: Icons.link_rounded,
                        label: 'Implemento',
                        color: AppColors.earth,
                        background: AppColors.earthSoft,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

// Ícone do item, trocado por um "check" quando selecionado
class _ItemBadge extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final Color color;
  final Color background;

  const _ItemBadge({
    required this.selected,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: selected
          ? const IconBadge(
              key: ValueKey('selected'),
              icon: Icons.check_rounded,
              size: 52,
              color: Colors.white,
              background: AppColors.primary,
            )
          : IconBadge(
              key: const ValueKey('item'),
              icon: icon,
              size: 52,
              color: color,
              background: background,
            ),
    );
  }
}

class _ItemTitle extends StatelessWidget {
  final String text;

  const _ItemTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _ItemSubtitle extends StatelessWidget {
  final String text;

  const _ItemSubtitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
