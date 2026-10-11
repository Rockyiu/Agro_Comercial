import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/selection_action_bar.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'warehouse_controller.dart';
import 'warehouse_state.dart';

// Aba "Armazém" da Home: galpões da fazenda ativa
class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final _controller = locator.get<WarehouseController>();
  final _farmController = locator.get<FarmController>();

  // Lista que guarda o ID dos armazéns selecionados
  Set<String> selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Garante que o carregamento só inicie após a tela estar 100% desenhada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadWarehouseData();
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

  Future<void> _showDeleteMultipleDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Selecionados",
      message:
          "Tem certeza que deseja excluir ${selectedIds.length} armazém(ns)? Todas as máquinas e produtos neles também serão apagados!",
    );
    if (!confirmed || !mounted) return;
    _controller.deleteSelectedWarehouses(selectedIds.toList());
    setState(() => selectedIds.clear()); // Limpa a seleção após excluir
  }

  Future<void> _registerWarehouse() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterWarehousePage()),
    );
    _controller.loadWarehouseData();
  }

  Future<void> _openWarehouse(WarehouseModel warehouse) async {
    // Se tiver selecionando, o clique normal também seleciona. Se não, abre a tela!
    if (selectedIds.isNotEmpty) {
      _toggleSelection(warehouse.id!);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WarehouseDetailsPage(warehouse: warehouse),
      ),
    );
    // O armazém pode ter sido renomeado ou excluído
    _controller.loadWarehouseData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final state = _controller.state;

        if (state is WarehouseLoadingState || state is WarehouseInitialState) {
          return const CustomCircularProgressIndicator();
        }

        if (state is WarehouseErrorState) {
          return Center(
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Algo deu errado',
              message: state.message,
              action: TextButton.icon(
                onPressed: _controller.loadWarehouseData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ),
          );
        }

        if (state is WarehouseSuccessState) {
          return RefreshIndicator(
            onRefresh: _controller.loadWarehouseData,
            child: _buildList(state.warehouses),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildList(List<WarehouseModel> warehouses) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        FadeSlideIn(
          child: PageHero(
            icon: Icons.warehouse_rounded,
            eyebrow: 'Estrutura da fazenda',
            title: 'Armazéns e estoque',
            subtitle:
                'Galpões, máquinas, implementos e insumos guardados na fazenda.',
            metrics: [
              HeroMetric(
                icon: Icons.warehouse_rounded,
                label: 'Armazéns',
                value: '${warehouses.length}',
              ),
              HeroMetric(
                icon: Icons.landscape_rounded,
                label: 'Fazenda',
                value: _farmController.selectedFarm?.name ?? '-',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (warehouses.isEmpty)
          EmptyState(
            icon: Icons.warehouse_rounded,
            title: 'Nenhum armazém cadastrado',
            message:
                'Cadastre o primeiro galpão para organizar as máquinas e o estoque de insumos da fazenda.',
            action: PrimaryButton(
              text: 'Cadastrar armazém',
              icon: Icons.add_rounded,
              onPressed: _registerWarehouse,
            ),
          )
        else ...[
          SectionHeader(
            title: 'Meus armazéns',
            subtitle: warehouses.length == 1
                ? '1 armazém nesta fazenda'
                : '${warehouses.length} armazéns nesta fazenda',
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: selectedIds.isEmpty
                ? const SizedBox(width: double.infinity)
                : SelectionActionBar(
                    label: "${selectedIds.length} selecionado(s)",
                    margin: const EdgeInsets.only(bottom: 12),
                    borderRadius: BorderRadius.circular(16),
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    onClear: () => setState(() => selectedIds.clear()),
                    onDelete: _showDeleteMultipleDialog,
                  ),
          ),
          for (var i = 0; i < warehouses.length; i++)
            FadeSlideIn(
              index: i + 1,
              child: _WarehouseCard(
                warehouse: warehouses[i],
                selected: selectedIds.contains(warehouses[i].id),
                onTap: () => _openWarehouse(warehouses[i]),
                onLongPress: () => _toggleSelection(warehouses[i].id!),
              ),
            ),
        ],
      ],
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final WarehouseModel warehouse;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _WarehouseCard({
    required this.warehouse,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          // Galpão ou "check" quando selecionado
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: selected
                ? const IconBadge(
                    key: ValueKey('selected'),
                    icon: Icons.check_rounded,
                    size: 50,
                    color: Colors.white,
                    background: AppColors.primary,
                  )
                : const IconBadge(
                    key: ValueKey('warehouse'),
                    icon: Icons.warehouse_rounded,
                    size: 50,
                    color: AppColors.earth,
                    background: AppColors.earthSoft,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warehouse.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.agriculture_rounded,
                      size: 14,
                      color: AppColors.inkMuted,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.inventory_2_rounded,
                      size: 14,
                      color: AppColors.inkMuted,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Máquinas e insumos',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          color: AppColors.inkMuted,
                        ),
                      ),
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
