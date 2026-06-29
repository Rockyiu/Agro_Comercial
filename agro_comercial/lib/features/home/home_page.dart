import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_controller.dart';
import 'package:agro_comercial/features/operation/operation_controller.dart';
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
import 'package:flutter/material.dart';
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

  final _farmService = locator.get<FarmService>();

  FarmModel? _fazendaAtiva;

  // ADICIONADO: Inicialização automática da fazenda ao abrir o App!
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarFazendaAtiva();
    });
  }

  // Busca a última fazenda usada no SharedPreferences via FarmController
  Future<void> _inicializarFazendaAtiva() async {
    final farmController = locator.get<FarmController>();
    await farmController.loadFarms();

    if (farmController.selectedFarm != null) {
      setState(() {
        _fazendaAtiva = farmController.selectedFarm;
      });
      // Avisa os outros módulos para carregarem os dados desta fazenda
      locator.get<WarehouseController>().loadWarehouseData();
      locator.get<OperationController>().loadOperationsData();
      locator.get<FieldOperationController>().loadOperationsData();
    }
  }

  Future<void> _mostrarSeletorDeFazendas(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.greenlightOne),
      ),
    );

    try {
      final fazendas = await _farmService.getFarmsByOwner(user.uid);

      if (!context.mounted) return;
      Navigator.pop(context); // Fecha o loading

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
                      'Área: ${fazenda.area} | Talhões: ${fazenda.numberOfPlots}',
                    ),
                    onTap: () async {
                      // 1. Atualiza o visual da Home
                      setState(() {
                        _fazendaAtiva = fazenda;
                      });

                      // 2. Avisa o Controlador Global qual é a fazenda ativa
                      await locator.get<FarmController>().changeActiveFarm(
                        fazenda,
                      );

                      // 3. Força as abas a buscarem os dados no Firebase usando a nova fazenda!
                      locator.get<WarehouseController>().loadWarehouseData();
                      locator.get<OperationController>().loadOperationsData();
                      locator
                          .get<FieldOperationController>()
                          .loadOperationsData();

                      if (!context.mounted) return;
                      Navigator.pop(context); // Fecha o seletor

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
      Navigator.pop(context); // Fecha o loading em caso de erro
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterMachinePage(),
                      ),
                    );
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterOperationPage(),
                      ),
                    );
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterProductPage(),
                      ),
                    );
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
                    locator.get<WarehouseController>().loadWarehouseData();
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterMachinePage(),
                      ),
                    );
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
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterProductPage(),
                      ),
                    );
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
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Vistorias'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FieldOperationPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Operações'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OperationPage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.people_outline,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Minha Equipe'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmployeePage(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline,
                      color: AppColors.greenlightOne,
                    ),
                    title: const Text('Meu Perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
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
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmRegistrationPage(),
                        ),
                      );
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
    // ADICIONADO: Bloqueia as abas se a fazenda não estiver selecionada
    if (_fazendaAtiva == null) {
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

    if (_currentIndex == 0) {
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text(
              'Visão Geral',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
          ),
          _buildSummaryCard(
            title: 'Custos Recentes',
            value: 'R\$ 1.450,00',
            subtitle: 'Compra de Agrotóxicos e Fertilizantes',
            icon: Icons.attach_money,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Última Operação',
            value: 'Trator Massey 95',
            subtitle: 'Operou por 5 hours - Talhão 02',
            icon: Icons.agriculture,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: 'Vistorias Recentes',
            value: 'Talhão 01',
            subtitle: 'Avaliação de pragas concluída com sucesso',
            icon: Icons.search,
            color: Colors.blueAccent,
          ),
        ],
      );
    } else if (_currentIndex == 2) {
      return const WarehousePage();
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppColors.lightkGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Página em construção',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.lightkGrey,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.midText20.copyWith(
                      color: AppColors.greenlightOne,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
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
