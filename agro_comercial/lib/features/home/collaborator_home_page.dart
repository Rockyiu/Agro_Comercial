import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/features/costs/cost_page.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/harvest/harvest_page.dart';
import 'package:agro_comercial/features/harvest/register_harvest_page.dart';
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
import 'widgets/farm_overview.dart';

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
          icon: Icons.travel_explore_rounded,
          title: 'Vistoria / Aplicação',
          subtitle: 'Condição do talhão, aplicação de produtos',
          onTap: () => _openPage(const RegisterFieldOperationPage()),
        ),
        AddMenuOption(
          icon: Icons.agriculture_rounded,
          title: 'Operação',
          subtitle: 'Plantio, colheita, aplicação',
          onTap: () => _openPage(const RegisterOperationPage()),
        ),
        // Só para colaboradores liberados pelo produtor em "Minha Equipe"
        if (_controller.canRegisterHarvest)
          AddMenuOption(
            icon: Icons.grass_rounded,
            title: 'Colheita',
            subtitle: 'Produção do talhão e preço de venda',
            onTap: () => _openPage(const RegisterHarvestPage()),
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
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PORTAL DO COLABORADOR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  farm?.name ?? 'Área do Colaborador',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // Menu lateral limitado para o colaborador
          drawer: AppDrawer(
            title: 'Portal do Colaborador',
            subtitle: farm != null
                ? 'Vinculado à ${farm.name}'
                : 'Sem fazenda vinculada',
            items: [
              // Reconstrói quando a permissão de colheita é carregada
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _controller.canRegisterHarvest
                    ? DrawerMenuItem(
                        icon: Icons.grass_rounded,
                        title: 'Minhas Colheitas',
                        onTap: () =>
                            _openPage(const HarvestPage(onlyMine: true)),
                      )
                    : const SizedBox.shrink(),
              ),
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
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(
              key: ValueKey(_currentIndex),
              child: _buildBody(),
            ),
          ),
          // Botão de registro rápido apenas na aba Início
          floatingActionButton: _currentIndex == _homeTab && farm != null
              ? FloatingActionButton.extended(
                  onPressed: _showAddMenu,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar'),
                )
              : null,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
                // Ao voltar para o Início, atualiza o que foi registrado nas outras abas
                if (index == _homeTab) _controller.loadActivities();
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.travel_explore_outlined),
                  selectedIcon: Icon(Icons.travel_explore_rounded),
                  label: 'Vistorias',
                ),
                NavigationDestination(
                  icon: Icon(Icons.agriculture_outlined),
                  selectedIcon: Icon(Icons.agriculture_rounded),
                  label: 'Operações',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: 'Custos',
                ),
              ],
            ),
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
              icon: Icons.home_work_rounded,
              title: 'Nenhuma fazenda vinculada',
              message:
                  'Você ainda não foi vinculado a uma fazenda.\nPeça ao produtor para adicionar você em "Minha Equipe".',
            ),
          );
        }

        if (state is CollaboratorHomeErrorState) {
          return Center(
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Algo deu errado',
              message: state.message,
              action: FilledButton.icon(
                onPressed: () => _controller.loadActivities(reloadFarm: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ),
          );
        }

        if (state is! CollaboratorHomeSuccessState) {
          return const CustomCircularProgressIndicator();
        }

        final farm = _farmController.selectedFarm;
        return ActivityFeed(
          title: 'Minhas atividades',
          header: [
            if (farm != null) FadeSlideIn(child: FarmHeroCard(farm: farm)),
          ],
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
            icon: Icons.inbox_rounded,
            title: 'Nenhuma atividade ainda',
            message:
                'Você ainda não registrou nenhuma operação, vistoria ou aplicação.\nToque em "Registrar" para lançar a primeira.',
            padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          ),
        );
      },
    );
  }
}
