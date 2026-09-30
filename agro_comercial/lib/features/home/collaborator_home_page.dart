import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/features/costs/cost_page.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/operation/operation_details_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart';
import 'package:agro_comercial/features/operation/register_operation_page.dart';
import 'package:agro_comercial/features/profile/profile_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'collaborator_home_controller.dart';
import 'collaborator_home_state.dart';
import 'widgets/activity_feed.dart';
import 'widgets/add_menu_sheet.dart';
import 'widgets/app_drawer.dart';

class CollaboratorHomePage extends StatefulWidget {
  const CollaboratorHomePage({super.key});

  @override
  State<CollaboratorHomePage> createState() => _CollaboratorHomePageState();
}

class _CollaboratorHomePageState extends State<CollaboratorHomePage> {
  // Abas da barra inferior
  static const _homeTab = 0;
  static const _inspectionsTab = 1;
  static const _operationsTab = 2;
  static const _costsTab = 3;

  int _currentIndex = _homeTab;

  final _farmController = locator.get<FarmController>();
  final _controller = locator.get<CollaboratorHomeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ao abrir a tela sempre busca a fazenda vinculada ao colaborador
      _controller.loadActivities(reloadFarm: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Abre uma tela e, ao voltar, atualiza as atividades
  Future<void> _openPage(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _controller.loadActivities();
  }

  void _showAddMenu() {
    showAddMenuSheet(
      context,
      title: 'O que deseja registrar?',
      options: [
        AddMenuOption(
          icon: Icons.assignment_turned_in_outlined,
          title: 'Vistoria / Aplicação',
          subtitle: 'Condição do talhão, aplicação de produtos',
          onTap: () => _openPage(const RegisterFieldOperationPage()),
        ),
        AddMenuOption(
          icon: Icons.build,
          title: 'Operação',
          subtitle: 'Plantio, colheita, aplicação',
          onTap: () => _openPage(const RegisterOperationPage()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reconstrói o título/drawer quando a fazenda do colaborador for carregada
    return ListenableBuilder(
      listenable: _farmController,
      builder: (context, _) {
        final farm = _farmController.selectedFarm;

        return Scaffold(
          backgroundColor: AppColors.iceWhite,
          appBar: AppBar(
            backgroundColor: AppColors.greenlightOne,
            elevation: 0,
            title: Text(
              farm != null ? 'Fazenda: ${farm.name}' : 'Área do Colaborador',
              style: AppTextStyles.midText20.copyWith(color: Colors.white),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          // Menu lateral limitado para o colaborador
          drawer: AppDrawer(
            header: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portal do Colaborador',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (farm != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenlightOne.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Vinculado à:\n${farm.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
              ],
            ),
            items: [
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
            ],
          ),
          body: _buildBody(),
          // Botão de registro rápido apenas na aba Início
          floatingActionButton: _currentIndex == _homeTab && farm != null
              ? FloatingActionButton(
                  backgroundColor: AppColors.greenlightOne,
                  onPressed: _showAddMenu,
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                )
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.greenlightOne,
            unselectedItemColor: AppColors.lightkGrey,
            onTap: (index) {
              setState(() => _currentIndex = index);
              // Ao voltar para o Início, atualiza o que foi registrado nas outras abas
              if (index == _homeTab) _controller.loadActivities();
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in_outlined),
                label: 'Vistorias',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                label: 'Operações',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.attach_money),
                label: 'Custos',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      // As abas usam a barra de título da Home (sem uma segunda barra)
      case _inspectionsTab:
        return const FieldOperationPage(showAppBar: false);
      case _operationsTab:
        return const OperationPage(showAppBar: false);
      case _costsTab:
        return const CostPage(showAppBar: false);
      default:
        return _buildActivitiesTab();
    }
  }

  // --- ABA INÍCIO: ATIVIDADES REGISTRADAS PELO COLABORADOR ---

  Widget _buildActivitiesTab() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state is CollaboratorHomeNoFarmState) {
          return const Center(
            child: EmptyState(
              icon: Icons.home_work_outlined,
              title: 'Nenhuma fazenda vinculada',
              message:
                  'Você ainda não foi vinculado a uma fazenda.\nPeça ao produtor para adicionar você em "Minha Equipe".',
            ),
          );
        }

        if (state is CollaboratorHomeErrorState) {
          return Center(
            child: EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Algo deu errado',
              message: state.message,
              action: TextButton.icon(
                onPressed: () => _controller.loadActivities(reloadFarm: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          );
        }

        if (state is! CollaboratorHomeSuccessState) {
          return const Center(child: CustomCircularProgressIndicator());
        }

        return ActivityFeed(
          title: 'Minhas Atividades',
          operations: state.operations,
          fieldOperations: state.fieldOperations,
          onRefresh: () =>
              _controller.loadActivities(reloadFarm: true, showLoading: false),
          onOperationTap: (op) =>
              _openPage(OperationDetailsPage(operation: op)),
          onFieldOperationTap: (fOp) =>
              _openPage(FieldOperationDetailsPage(operation: fOp)),
          // Mostrado no primeiro acesso, enquanto o colaborador não registrou nada
          emptyState: const EmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nenhuma atividade ainda',
            message:
                'Você ainda não registrou nenhuma operação, vistoria ou aplicação.\nUse o botão verde (+) para registrar sua primeira atividade!',
            padding: EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
          ),
        );
      },
    );
  }
}
