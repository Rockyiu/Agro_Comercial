import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/features/cash_book/cash_book_page.dart';
import 'package:agro_comercial/features/costs/cost_page.dart';
import 'package:agro_comercial/features/employee/employee_page.dart';
import 'package:agro_comercial/features/farm/edit_farm_page.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/farm_registration/farm_registration_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/harvest/harvest_page.dart';
import 'package:agro_comercial/features/harvest/register_harvest_page.dart';
import 'package:agro_comercial/features/invoices/invoice_page.dart';
import 'package:agro_comercial/features/operation/operation_details_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart';
import 'package:agro_comercial/features/operation/register_operation_page.dart';
import 'package:agro_comercial/features/profile/profile_page.dart';
import 'package:agro_comercial/features/register_machine/register_machine_page.dart';
import 'package:agro_comercial/features/register_product/register_product_page.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/reports/production_reports_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'home_controller.dart';
import 'home_state.dart';
import 'widgets/activity_feed.dart';
import 'widgets/add_menu_sheet.dart';
import 'widgets/app_drawer.dart';
import 'widgets/farm_overview.dart';
import 'widgets/farm_selector_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Abas da barra inferior
  static const _homeTab = 0;
  static const _cashBookTab = 1;
  static const _warehouseTab = 2;
  static const _reportsTab = 3;

  int _currentIndex = _homeTab;

  final _farmController = locator.get<FarmController>();
  final _warehouseController = locator.get<WarehouseController>();
  final _homeController = locator.get<HomeController>();

  FarmModel? get _activeFarm => _farmController.selectedFarm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFarmData());
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  // Carrega a fazenda ativa e, com ela, armazéns e atividades
  Future<void> _loadFarmData() async {
    await _farmController.loadFarms();
    _reloadActiveFarmData();
  }

  void _reloadActiveFarmData() {
    if (_activeFarm == null) return;
    _warehouseController.loadWarehouseData();
    _homeController.loadActivities();
  }

  // Abre uma tela e, ao voltar, atualiza os dados da Home
  Future<void> _openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _loadFarmData();
  }

  Future<void> _switchFarm() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomCircularProgressIndicator()),
    );

    List<FarmModel> farms;
    try {
      farms = await _farmController.fetchOwnedFarms();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fecha o loading
      context.showErrorSnackBar(
        "Erro ao carregar as fazendas. Tente novamente.",
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // Fecha o loading

    if (farms.isEmpty) {
      context.showWarningSnackBar(
        "Nenhuma fazenda cadastrada. Cadastre uma propriedade primeiro!",
      );
      return;
    }

    final farm = await showFarmSelectorDialog(context, farms);
    if (farm == null || !mounted) return;

    await _farmController.changeActiveFarm(farm);
    _reloadActiveFarmData();
    if (!mounted) return;
    context.showSuccessSnackBar("Fazenda alterada para: ${farm.name}");
  }

  void _editActiveFarm() {
    final farm = _activeFarm;
    if (farm == null) {
      context.showWarningSnackBar('Nenhuma fazenda selecionada no momento.');
      return;
    }
    _openPage(EditFarmPage(farm: farm));
  }

  void _handleFabPressed() {
    if (_currentIndex == _homeTab) {
      showAddMenuSheet(
        context,
        title: 'O que deseja registrar?',
        options: [
          AddMenuOption(
            icon: Icons.agriculture_rounded,
            title: 'Cadastrar Máquina',
            subtitle: 'Trator, colhedora, implementos',
            onTap: () => _openPage(const RegisterMachinePage()),
          ),
          AddMenuOption(
            icon: Icons.handyman_rounded,
            title: 'Cadastrar Operação',
            subtitle: 'Plantio, colheita, aplicação',
            onTap: () => _openPage(const RegisterOperationPage()),
          ),
          AddMenuOption(
            icon: Icons.travel_explore_rounded,
            title: 'Cadastrar Vistoria / Aplicação',
            subtitle: 'Condição do talhão, aplicação de produtos',
            onTap: () => _openPage(const RegisterFieldOperationPage()),
          ),
          AddMenuOption(
            icon: Icons.inventory_2_rounded,
            title: 'Cadastrar Produto',
            subtitle: 'Insumos, sementes, defensivos, peças',
            onTap: () => _openPage(const RegisterProductPage()),
          ),
          AddMenuOption(
            icon: Icons.grass_rounded,
            title: 'Registrar Colheita',
            subtitle: 'Produção do talhão e preço de venda',
            onTap: () => _openPage(const RegisterHarvestPage()),
          ),
        ],
      );
    } else if (_currentIndex == _warehouseTab) {
      showAddMenuSheet(
        context,
        title: 'O que deseja adicionar?',
        options: [
          AddMenuOption(
            icon: Icons.warehouse_rounded,
            title: 'Novo Armazém',
            subtitle: 'Galpão, silo ou depósito',
            onTap: () => _openPage(const RegisterWarehousePage()),
          ),
          AddMenuOption(
            icon: Icons.agriculture_rounded,
            title: 'Nova Máquina',
            subtitle: 'Trator, colhedora, implementos',
            onTap: () => _openPage(const RegisterMachinePage()),
          ),
          AddMenuOption(
            icon: Icons.inventory_2_rounded,
            title: 'Novo Produto',
            subtitle: 'Insumos, sementes, agrotóxicos',
            onTap: () => _openPage(const RegisterProductPage()),
          ),
        ],
      );
    }
  }

  static const _tabs = [
    (
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      label: 'Início',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Livro Caixa',
    ),
    (
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse_rounded,
      label: 'Armazém',
    ),
    (
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      label: 'Relatórios',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _farmController,
      builder: (context, _) {
        final farm = _activeFarm;
        final showFab =
            farm != null &&
            (_currentIndex == _homeTab || _currentIndex == _warehouseTab);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: _FarmSwitcherTitle(farm: farm, onTap: _switchFarm),
            actions: [
              IconButton(
                tooltip: 'Notificações',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: _buildDrawer(farm),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _buildBody(farm),
            ),
          ),
          floatingActionButton: showFab
              ? FloatingActionButton.extended(
                  onPressed: _handleFabPressed,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    _currentIndex == _homeTab ? 'Registrar' : 'Adicionar',
                  ),
                )
              : null,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: [
                for (final tab in _tabs)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(FarmModel? farm) {
    return AppDrawer(
      title: farm?.name ?? 'Nenhuma fazenda ativa',
      subtitle: farm == null
          ? 'Escolha uma fazenda para começar'
          : 'CAD/PRO ${farm.cadPro}  •  ${farm.totalAreaLabel}',
      items: [
        const DrawerSection('Fazenda'),
        DrawerMenuItem(
          icon: Icons.landscape_rounded,
          title: 'Minha Fazenda',
          onTap: _editActiveFarm,
        ),
        DrawerMenuItem(
          icon: Icons.swap_horiz_rounded,
          title: 'Trocar de Fazenda',
          onTap: _switchFarm,
        ),
        DrawerMenuItem(
          icon: Icons.add_home_work_rounded,
          title: 'Cadastrar Nova Fazenda',
          onTap: () => _openPage(const FarmRegistrationPage()),
        ),
        const DrawerSection('Gestão'),
        DrawerMenuItem(
          icon: Icons.agriculture_rounded,
          title: 'Operações',
          onTap: () => _openPage(const OperationPage()),
        ),
        DrawerMenuItem(
          icon: Icons.travel_explore_rounded,
          title: 'Vistorias e Aplicações',
          onTap: () => _openPage(const FieldOperationPage()),
        ),
        DrawerMenuItem(
          icon: Icons.payments_rounded,
          title: 'Custos',
          onTap: () => _openPage(const CostPage()),
        ),
        DrawerMenuItem(
          icon: Icons.grass_rounded,
          title: 'Produção / Colheita',
          onTap: () => _openPage(const HarvestPage()),
        ),
        DrawerMenuItem(
          icon: Icons.groups_rounded,
          title: 'Minha Equipe',
          onTap: () => _openPage(const EmployeePage()),
        ),
        DrawerMenuItem(
          icon: Icons.receipt_long_rounded,
          title: 'Notas Fiscais',
          onTap: () => _openPage(const InvoicePage()),
        ),
        const DrawerSection('Conta'),
        DrawerMenuItem(
          icon: Icons.person_rounded,
          title: 'Meu Perfil',
          onTap: () => _openPage(const ProfilePage()),
        ),
        DrawerMenuItem(
          icon: Icons.settings_rounded,
          title: 'Configurações',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildBody(FarmModel? farm) {
    if (farm == null) {
      // Ainda buscando a fazenda salva
      if (_farmController.isLoading) {
        return const CustomCircularProgressIndicator();
      }
      return Center(
        child: EmptyState(
          icon: Icons.home_work_rounded,
          title: 'Nenhuma fazenda ativa',
          message:
              'Escolha uma das suas fazendas para carregar os dados, ou cadastre uma nova propriedade.',
          action: FilledButton.icon(
            onPressed: _switchFarm,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Escolher fazenda'),
          ),
        ),
      );
    }

    switch (_currentIndex) {
      case _cashBookTab:
        return const CashBookPage();
      case _warehouseTab:
        return const WarehousePage();
      case _reportsTab:
        // A key recria a aba ao trocar de fazenda
        return ProductionReportsPage(key: ValueKey('reports_${farm.id}'));
      default:
        return _buildActivitiesTab(farm);
    }
  }

  // --- ABA INÍCIO: PAINEL DA FAZENDA E ATIVIDADES (PRODUTOR + EQUIPE) ---

  Widget _buildActivitiesTab(FarmModel farm) {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        final state = _homeController.state;

        if (state is HomeErrorState) {
          return Center(
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Algo deu errado',
              message: state.message,
              action: FilledButton.icon(
                onPressed: _loadFarmData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ),
          );
        }

        if (state is! HomeSuccessState) {
          return const CustomCircularProgressIndicator();
        }

        final inspections = state.fieldOperations
            .where((op) => op.isInspection)
            .length;

        return ActivityFeed(
          title: 'Atividades recentes',
          header: [
            FadeSlideIn(
              child: FarmHeroCard(farm: farm, onTap: _editActiveFarm),
            ),
            FadeSlideIn(
              index: 1,
              child: Row(
                children: [
                  Expanded(
                    child: StatTile(
                      icon: Icons.agriculture_rounded,
                      label: 'Operações',
                      value: '${state.operations.length}',
                      color: AppColors.earth,
                      background: AppColors.earthSoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.travel_explore_rounded,
                      label: 'Vistorias',
                      value: '$inspections',
                      color: AppColors.sky,
                      background: AppColors.skySoft,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatTile(
                      icon: Icons.water_drop_rounded,
                      label: 'Aplicações',
                      value: '${state.fieldOperations.length - inspections}',
                      color: AppColors.water,
                      background: AppColors.waterSoft,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: SectionHeader(title: 'Acesso rápido'),
                ),
                QuickActionsGrid(actions: _quickActions()),
              ],
            ),
          ],
          operations: state.operations,
          fieldOperations: state.fieldOperations,
          authorName: state.authorName,
          onRefresh: () => _homeController.loadActivities(showLoading: false),
          onOperationTap: (op) =>
              _openPage(OperationDetailsPage(operation: op)),
          onFieldOperationTap: (fOp) =>
              _openPage(FieldOperationDetailsPage(operation: fOp)),
          emptyState: const EmptyState(
            icon: Icons.inbox_rounded,
            title: 'Nenhuma atividade ainda',
            message:
                'Ainda não há operações, vistorias ou aplicações nesta fazenda.\nToque em "Registrar" para lançar a primeira.',
            padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          ),
        );
      },
    );
  }

  List<QuickAction> _quickActions() => [
    QuickAction(
      icon: Icons.agriculture_rounded,
      label: 'Operações',
      color: AppColors.earth,
      background: AppColors.earthSoft,
      onTap: () => _openPage(const OperationPage()),
    ),
    QuickAction(
      icon: Icons.travel_explore_rounded,
      label: 'Vistorias',
      color: AppColors.sky,
      background: AppColors.skySoft,
      onTap: () => _openPage(const FieldOperationPage()),
    ),
    QuickAction(
      icon: Icons.payments_rounded,
      label: 'Custos',
      color: AppColors.harvestDark,
      background: AppColors.harvestSoft,
      onTap: () => _openPage(const CostPage()),
    ),
    QuickAction(
      icon: Icons.grass_rounded,
      label: 'Colheita',
      color: AppColors.primary,
      background: AppColors.primarySoft,
      onTap: () => _openPage(const HarvestPage()),
    ),
    QuickAction(
      icon: Icons.inventory_2_rounded,
      label: 'Estoque',
      color: AppColors.primary,
      background: AppColors.primarySoft,
      onTap: () => setState(() => _currentIndex = _warehouseTab),
    ),
    QuickAction(
      icon: Icons.groups_rounded,
      label: 'Equipe',
      color: AppColors.water,
      background: AppColors.waterSoft,
      onTap: () => _openPage(const EmployeePage()),
    ),
    QuickAction(
      icon: Icons.receipt_long_rounded,
      label: 'Notas',
      color: AppColors.earth,
      background: AppColors.earthSoft,
      onTap: () => _openPage(const InvoicePage()),
    ),
    QuickAction(
      icon: Icons.insights_rounded,
      label: 'Relatórios',
      color: AppColors.harvestDark,
      background: AppColors.harvestSoft,
      onTap: () => setState(() => _currentIndex = _reportsTab),
    ),
  ];
}

// Título da barra: fazenda ativa, com toque para trocar de fazenda
class _FarmSwitcherTitle extends StatelessWidget {
  final FarmModel? farm;
  final VoidCallback onTap;

  const _FarmSwitcherTitle({required this.farm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final farm = this.farm;
    if (farm == null) return const Text('Gestão Rural');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FAZENDA ATIVA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    farm.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.harvest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
