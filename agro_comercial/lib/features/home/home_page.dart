import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/register_machine/register_machine_page.dart';
import 'package:agro_comercial/features/register_product/register_product_page.dart';
import 'package:agro_comercial/features/warehouse/warehouse_page.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart'; // NOVO IMPORT DA PÁGINA DE OPERAÇÕES
import 'package:flutter/material.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Função que decide qual menu abrir dependendo da aba selecionada
  void _handleFabPressed() {
    if (_currentIndex == 0) {
      _showHomeAddMenu();
    } else if (_currentIndex == 2) {
      _showWarehouseAddMenu();
    }
  }

  // Menu da Aba Início
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
                    setState(() {
                      _currentIndex = 3; // Joga para a aba de operações
                    });
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
                    Navigator.pop(context); // Fecha menu inferior
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

  // Menu da Aba Armazém
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
          'Gestão Rural',
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
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.greenlightOne),
              child: Text(
                'Menu Gestão Rural',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
                Navigator.pop(context); // Fecha o drawer lateral
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterFieldOperationPage(),
                  ),
                );
              },
            ),
            // ADICIONADO: Opção Operações Campo logo abaixo de Vistorias
            ListTile(
              leading: const Icon(
                Icons.assignment_outlined,
                color: AppColors.greenlightOne,
              ),
              title: const Text('Operações'),
              onTap: () {
                Navigator.pop(context);
                setState(
                  () => _currentIndex = 3,
                ); // Joga direto para a aba de histórico de operações!
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
          ],
        ),
      ),
      body: _buildBody(),

      // O Botão agora só aparece se estivermos na aba Home (0) ou Armazém (2)
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
              // ATUALIZADO: O item 3 do menu inferior agora direciona para as Operações
              _buildTabItem(
                icon: Icons.assignment_outlined,
                index: 3,
                label: 'Operações',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
            subtitle: 'Operou por 5 horas - Talhão 02',
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
      // ADICIONADO: Ao selecionar a aba 3 (ou clicar no drawer), renderiza o OperationPage
      return const OperationPage();
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: AppColors.lightkGrey.withOpacity(0.5),
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
              backgroundColor: color.withOpacity(0.15),
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
