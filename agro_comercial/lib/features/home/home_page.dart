import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/features/operation/operation_details_page.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/activity_card.dart';

import 'package:agro_comercial/features/cash_book/cash_book_page.dart';
import 'package:agro_comercial/features/costs/cost_page.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/farm/edit_farm_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';
import 'package:agro_comercial/features/employee/employee_page.dart';
import 'package:agro_comercial/features/farm_registration/farm_registration_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/register_machine/register_machine_page.dart';
import 'package:agro_comercial/features/register_product/register_product_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_page.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart';
import 'package:agro_comercial/features/operation/register_operation_page.dart';
import 'package:agro_comercial/features/profile/profile_page.dart';
import 'package:agro_comercial/services/farm_service/farm_service.dart';
import 'package:agro_comercial/features/invoices/invoice_page.dart';
import 'package:flutter/material.dart';
import 'home_controller.dart';
import 'home_state.dart';
import 'package:agro_comercial/locator.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/features/sign_in/sign_in_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Trazemos os controladores para o nível da classe para eles não perderem a memória
  final _farmService = locator.get<FarmService>();
  final _farmController = locator.get<FarmController>();
  final _warehouseController = locator.get<WarehouseController>();
  final _homeController = locator.get<HomeController>();

  FarmModel? _fazendaAtiva;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarFazendaAtiva();
    });
  }

  Future<void> _inicializarFazendaAtiva() async {
    await _farmController.loadFarms();

    if (_farmController.selectedFarm != null) {
      setState(() {
        _fazendaAtiva = _farmController.selectedFarm;
      });
      _warehouseController.loadWarehouseData();
      _homeController.loadActivities();
    }
  }

  @override
  void dispose() {
    _homeController.dispose();
    super.dispose();
  }

  Future<void> _mostrarSeletorDeFazendas(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CustomCircularProgressIndicator()),
    );

    try {
      final fazendas = await _farmService.getFarmsByOwner(user.uid);

      if (!context.mounted) return;
      Navigator.pop(context);

      if (fazendas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Nenhuma fazenda cadastrada. Cadastre uma propriedade primeiro!",
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Selecione a Fazenda"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: fazendas.length,
                itemBuilder: (context, index) {
                  final fazenda = fazendas[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.home_work,
                      color: AppColors.greenlightOne,
                    ),
                    title: Text(fazenda.name),
                    subtitle: Text(
                      'Área: ${fazenda.totalArea} | Talhões: ${fazenda.plantedFields.length}',
                    ),
                    onTap: () async {
                      setState(() {
                        _fazendaAtiva = fazenda;
                      });

                      await _farmController.changeActiveFarm(fazenda);

                      _warehouseController.loadWarehouseData();
                      _homeController.loadActivities();

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Fazenda alterada para: ${fazenda.name}",
                          ),
                          backgroundColor: AppColors.greenlightOne,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erro ao carregar as fazendas. Tente novamente."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleFabPressed() {
    if (_currentIndex == 0) {
      _showHomeAddMenu();
    } else if (_currentIndex == 2) {
      _showWarehouseAddMenu();
    }
  }

  void _showHomeAddMenu() {
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
                  'O que deseja registrar?',
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
                    _inicializarFazendaAtiva(); // Atualiza a Home ao voltar!
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.build, color: AppColors.greenlightOne),
                  ),
                  title: Text(
                    'Cadastrar Operação',
                    style: AppTextStyles.inputText,
                  ),
                  subtitle: Text(
                    'Plantio, colheita, aplicação',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterOperationPage(),
                      ),
                    );
                    _inicializarFazendaAtiva(); // Atualiza a Home ao voltar!
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text(
                    'Cadastrar Vistoria / Aplicação',
                    style: AppTextStyles.inputText,
                  ),
                  subtitle: Text(
                    'Condição do talhão, aplicação de produtos',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const RegisterFieldOperationPage(),
                      ),
                    );
                    _inicializarFazendaAtiva(); // Atualiza a Home ao voltar!
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
                    'Insumos, sementes, defensivos, peças',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterProductPage(),
                      ),
                    );
                    _inicializarFazendaAtiva(); // Atualiza a Home ao voltar!
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWarehouseAddMenu() {
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
                  'O que deseja adicionar?',
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.greenlightOne,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.warehouse,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text('Novo Armazém', style: AppTextStyles.inputText),
                  subtitle: Text(
                    'Galpão, silo ou depósito',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterWarehousePage(),
                      ),
                    );
                    _inicializarFazendaAtiva();
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.agriculture,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text('Nova Máquina', style: AppTextStyles.inputText),
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
                    _inicializarFazendaAtiva();
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
                  title: Text('Novo Produto', style: AppTextStyles.inputText),
                  subtitle: Text(
                    'Insumos, sementes, agrotóxicos',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterProductPage(),
                      ),
                    );
                    _inicializarFazendaAtiva();
                  },
                ),
              ],
            ),
          ),
        );
      },
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
          _fazendaAtiva != null
              ? 'Fazenda: ${_fazendaAtiva!.name}'
              : 'Gestão Rural',
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.iceWhite,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: AppColors.greenlightOne,
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Column(
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
                          if (_fazendaAtiva != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'CAD/PRO: ${_fazendaAtiva!.cadPro}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.landscape,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Minha Fazenda'),
                    onTap: () async {
                      Navigator.pop(context);
                      final activeFarm = _farmController.selectedFarm;
                      if (activeFarm != null) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditFarmPage(farm: activeFarm),
                          ),
                        );
                        _inicializarFazendaAtiva();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Nenhuma fazenda selecionada no momento.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Vistorias'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FieldOperationPage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Operações'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OperationPage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.attach_money,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Custos'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CostPage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Minha Equipe'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployeePage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.receipt_long,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Notas Fiscais'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoicePage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Meu Perfil'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Configurações'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.add_home_work,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Cadastrar Nova Fazenda'),
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmRegistrationPage(),
                        ),
                      );
                      _inicializarFazendaAtiva();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.swap_horiz,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Trocar de Fazenda'),
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarSeletorDeFazendas(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Sair',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) {
                  return;
                }

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: _buildBody(),

      floatingActionButton: (_currentIndex == 0 || _currentIndex == 2)
          ? FloatingActionButton(
              backgroundColor: AppColors.greenlightOne,
              onPressed: _handleFabPressed,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 36),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                icon: Icons.home_outlined,
                index: 0,
                label: 'Início',
              ),
              _buildTabItem(
                icon: Icons.request_quote_outlined,
                index: 1,
                label: 'Livro Caixa',
              ),
              const SizedBox(width: 48),
              _buildTabItem(
                icon: Icons.warehouse_outlined,
                index: 2,
                label: 'Armazém',
              ),
              _buildTabItem(
                icon: Icons.bar_chart_outlined,
                index: 3,
                label: 'Relatório',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_fazendaAtiva == null) {
      return _buildFarmEmptyState();
    }

    if (_currentIndex == 0) {
      return _buildActivitiesTab();
    } else if (_currentIndex == 2) {
      return const WarehousePage();
    } else if (_currentIndex == 1) {
      return const CashBookPage();
    } else if (_currentIndex == 3) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 64,
              color: AppColors.lightkGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Relatórios em construção',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.lightkGrey,
              ),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // --- COMPONENTES VISUAIS SEPARADOS PARA ORGANIZAR O CÓDIGO ---

  // --- ABA INÍCIO: ATIVIDADES DA FAZENDA (PRODUTOR + EQUIPE) ---

  Widget _buildActivitiesTab() {
    return ListenableBuilder(
      listenable: _homeController,
      builder: (context, _) {
        final state = _homeController.state;

        if (state is HomeInitialState || state is HomeLoadingState) {
          return const Center(child: CustomCircularProgressIndicator());
        }

        if (state is HomeErrorState) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 80,
                    color: AppColors.lightkGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Algo deu errado',
                    style: AppTextStyles.midText20.copyWith(
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _inicializarFazendaAtiva,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final successState = state as HomeSuccessState;

        return RefreshIndicator(
          color: AppColors.greenlightOne,
          onRefresh: _homeController.loadActivities,
          child: ListView(
            // Permite o "puxar para atualizar" mesmo com a lista vazia
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Text(
                  'Atividades da Fazenda',
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.greenlightOne,
                  ),
                ),
              ),
              if (successState.isEmpty)
                _buildEmptyHomeState()
              else
                ..._buildActivityCards(successState),
            ],
          ),
        );
      },
    );
  }

  // Junta operações e vistorias/aplicações, da mais recente para a mais antiga
  List<Widget> _buildActivityCards(HomeSuccessState state) {
    final combinedList = <({int timestamp, Widget widget})>[
      for (final op in state.operations)
        (
          timestamp: op.dateTimestamp,
          widget: _buildOperationCard(
            op,
            registeredBy: state.authorName(op.createdBy),
          ),
        ),
      for (final fOp in state.fieldOperations)
        (
          timestamp: fOp.dateTimestamp,
          widget: _buildFieldOperationCard(
            fOp,
            registeredBy: state.authorName(fOp.createdBy),
          ),
        ),
    ];

    combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return combinedList.map((e) => e.widget).toList();
  }

  Widget _buildFarmEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 80,
              color: AppColors.lightkGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma fazenda ativa',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Abra o menu lateral (☰) e escolha "Trocar de Fazenda" para carregar seus dados.',
              textAlign: TextAlign.center,
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHomeState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: AppColors.lightkGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma atividade ainda',
            style: AppTextStyles.midText20.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ainda não há operações, vistorias ou aplicações cadastradas nesta fazenda.\nUse o botão verde (+) abaixo para cadastrar a primeira atividade!',
            textAlign: TextAlign.center,
            style: AppTextStyles.smallText.copyWith(
              color: AppColors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(OperationModel operation, {String? registeredBy}) {
    return OperationActivityCard(
      operation: operation,
      registeredBy: registeredBy,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OperationDetailsPage(operation: operation),
          ),
        );
        _inicializarFazendaAtiva();
      },
    );
  }

  Widget _buildFieldOperationCard(
    FieldOperationModel fieldOperation, {
    String? registeredBy,
  }) {
    return FieldOperationActivityCard(
      fieldOperation: fieldOperation,
      registeredBy: registeredBy,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FieldOperationDetailsPage(operation: fieldOperation),
          ),
        );
        _inicializarFazendaAtiva();
      },
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.greenlightOne
                  : AppColors.lightkGrey,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.greenlightOne
                    : AppColors.lightkGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
