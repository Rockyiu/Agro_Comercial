import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
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
            icon: Icons.agriculture,
            title: 'Cadastrar Máquina',
            subtitle: 'Trator, colhedora, implementos',
            onTap: () => _openPage(const RegisterMachinePage()),
          ),
          AddMenuOption(
            icon: Icons.build,
            title: 'Cadastrar Operação',
            subtitle: 'Plantio, colheita, aplicação',
            onTap: () => _openPage(const RegisterOperationPage()),
          ),
          AddMenuOption(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Cadastrar Vistoria / Aplicação',
            subtitle: 'Condição do talhão, aplicação de produtos',
            onTap: () => _openPage(const RegisterFieldOperationPage()),
          ),
          AddMenuOption(
            icon: Icons.inventory,
            title: 'Cadastrar Produto',
            subtitle: 'Insumos, sementes, defensivos, peças',
            onTap: () => _openPage(const RegisterProductPage()),
          ),
          AddMenuOption(
            icon: Icons.grass,
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
            icon: Icons.warehouse,
            title: 'Novo Armazém',
            subtitle: 'Galpão, silo ou depósito',
            onTap: () => _openPage(const RegisterWarehousePage()),
          ),
          AddMenuOption(
            icon: Icons.agriculture,
            title: 'Nova Máquina',
            subtitle: 'Trator, colhedora, implementos',
            onTap: () => _openPage(const RegisterMachinePage()),
          ),
          AddMenuOption(
            icon: Icons.inventory,
            title: 'Novo Produto',
            subtitle: 'Insumos, sementes, agrotóxicos',
            onTap: () => _openPage(const RegisterProductPage()),
          ),
        ],
      );
    }
  }

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
          backgroundColor: AppColors.iceWhite,
          appBar: AppBar(
            backgroundColor: AppColors.greenlightOne,
            elevation: 0,
            title: Text(
              farm != null ? 'Fazenda: ${farm.name}' : 'Gestão Rural',
              style: AppTextStyles.midText20.copyWith(color: Colors.white),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          drawer: _buildDrawer(farm),
          body: _buildBody(farm),
          floatingActionButton: showFab
              ? FloatingActionButton(
                  backgroundColor: AppColors.greenlightOne,
                  onPressed: _handleFabPressed,
                  elevation: 4,
                  child: const Icon(Icons.add, color: Colors.white, size: 36),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTabItem(Icons.home_outlined, _homeTab, 'Início'),
                  _buildTabItem(
                    Icons.request_quote_outlined,
                    _cashBookTab,
                    'Livro Caixa',
                  ),
                  const SizedBox(width: 48), // Espaço do botão (+)
                  _buildTabItem(
                    Icons.warehouse_outlined,
                    _warehouseTab,
                    'Armazém',
                  ),
                  _buildTabItem(
                    Icons.bar_chart_outlined,
                    _reportsTab,
                    'Relatório',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(FarmModel? farm) {
    return AppDrawer(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Gestão Rural',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (farm != null) ...[
            const SizedBox(height: 6),
            Text(
              'CAD/PRO: ${farm.cadPro}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ],
      ),
      items: [
        DrawerMenuItem(
          icon: Icons.landscape,
          title: 'Minha Fazenda',
          onTap: _editActiveFarm,
        ),
        DrawerMenuItem(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Vistorias',
          onTap: () => _openPage(const FieldOperationPage()),
        ),
        DrawerMenuItem(
          icon: Icons.assignment_outlined,
          title: 'Operações',
          onTap: () => _openPage(const OperationPage()),
        ),
        DrawerMenuItem(
          icon: Icons.attach_money,
          title: 'Custos',
          onTap: () => _openPage(const CostPage()),
        ),
        DrawerMenuItem(
          icon: Icons.grass,
          title: 'Produção / Colheita',
          onTap: () => _openPage(const HarvestPage()),
        ),
        DrawerMenuItem(
          icon: Icons.people_outline,
          title: 'Minha Equipe',
          onTap: () => _openPage(const EmployeePage()),
        ),
        DrawerMenuItem(
          icon: Icons.receipt_long,
          title: 'Notas Fiscais',
          onTap: () => _openPage(const InvoicePage()),
        ),
        DrawerMenuItem(
          icon: Icons.person_outline,
          title: 'Meu Perfil',
          onTap: () => _openPage(const ProfilePage()),
        ),
        DrawerMenuItem(
          icon: Icons.settings,
          title: 'Configurações',
          onTap: () {},
        ),
        const Divider(),
        DrawerMenuItem(
          icon: Icons.add_home_work,
          title: 'Cadastrar Nova Fazenda',
          onTap: () => _openPage(const FarmRegistrationPage()),
        ),
        DrawerMenuItem(
          icon: Icons.swap_horiz,
          title: 'Trocar de Fazenda',
          onTap: _switchFarm,
        ),
      ],
    );
  }

  Widget _buildBody(FarmModel? farm) {
    if (farm == null) {
      // Ainda buscando a fazenda salva
      if (_farmController.isLoading) {
        return const Center(child: CustomCircularProgressIndicator());
      }
      return const Center(
        child: EmptyState(
          icon: Icons.home_work_outlined,
          title: 'Nenhuma fazenda ativa',
          message:
              'Abra o menu lateral (☰) e escolha "Trocar de Fazenda" para carregar seus dados.',
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
        return _buildActivitiesTab();
    }
  }

  // --- ABA INÍCIO: ATIVIDADES DA FAZENDA (PRODUTOR + EQUIPE) ---

  Widget _buildActivitiesTab() {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        final state = _homeController.state;

        if (state is HomeErrorState) {
          return Center(
            child: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Algo deu errado',
              message: state.message,
              action: TextButton.icon(
                onPressed: _loadFarmData,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          );
        }

        if (state is! HomeSuccessState) {
          return const Center(child: CustomCircularProgressIndicator());
        }

        return ActivityFeed(
          title: 'Atividades da Fazenda',
          operations: state.operations,
          fieldOperations: state.fieldOperations,
          authorName: state.authorName,
          onRefresh: () => _homeController.loadActivities(showLoading: false),
          onOperationTap: (op) =>
              _openPage(OperationDetailsPage(operation: op)),
          onFieldOperationTap: (fOp) =>
              _openPage(FieldOperationDetailsPage(operation: fOp)),
          emptyState: const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nenhuma atividade ainda',
            message:
                'Ainda não há operações, vistorias ou aplicações cadastradas nesta fazenda.\nUse o botão verde (+) abaixo para cadastrar a primeira atividade!',
            padding: EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
          ),
        );
      },
    );
  }

  Widget _buildTabItem(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.greenlightOne : AppColors.lightkGrey;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
