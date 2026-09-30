import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/widgets/activity_card.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_details_page.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/field_operations/register_field_operation_page.dart';
import 'package:agro_comercial/features/operation/operation_details_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart';
import 'package:agro_comercial/features/operation/register_operation_page.dart';
import 'package:agro_comercial/features/profile/profile_page.dart';
import 'package:agro_comercial/features/sign_in/sign_in_page.dart';
import 'package:agro_comercial/features/costs/cost_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'collaborator_home_controller.dart';
import 'collaborator_home_state.dart';

class CollaboratorHomePage extends StatefulWidget {
  const CollaboratorHomePage({super.key});

  @override
  State<CollaboratorHomePage> createState() => _CollaboratorHomePageState();
}

class _CollaboratorHomePageState extends State<CollaboratorHomePage> {
  int _currentIndex = 0;

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

  Future<void> _openAndRefresh(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _controller.loadActivities();
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
                      Icons.assignment_turned_in_outlined,
                      color: AppColors.greenlightOne,
                    ),
                  ),
                  title: Text(
                    'Vistoria / Aplicação',
                    style: AppTextStyles.inputText,
                  ),
                  subtitle: Text(
                    'Condição do talhão, aplicação de produtos',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openAndRefresh(const RegisterFieldOperationPage());
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.build, color: AppColors.greenlightOne),
                  ),
                  title: Text('Operação', style: AppTextStyles.inputText),
                  subtitle: Text(
                    'Plantio, colheita, aplicação',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openAndRefresh(const RegisterOperationPage());
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
    // Reconstrói o título/drawer quando a fazenda do colaborador for carregada
    return ListenableBuilder(
      listenable: _farmController,
      builder: (context, _) {
        final fazendaAtiva = _farmController.selectedFarm;

        return Scaffold(
          backgroundColor: AppColors.iceWhite,
          appBar: AppBar(
            backgroundColor: AppColors.greenlightOne,
            elevation: 0,
            title: Text(
              fazendaAtiva != null
                  ? 'Fazenda: ${fazendaAtiva.name}'
                  : 'Área do Colaborador',
              style: AppTextStyles.midText20.copyWith(color: Colors.white),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),

          // DRAWER LIMITADO PARA O COLABORADOR
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
                                'Portal do Colaborador',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (fazendaAtiva != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenlightOne.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Vinculado à:\n${fazendaAtiva.name}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
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
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInPage(),
                      ),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // CORPO (PÁGINAS)
          body: _buildBody(),

          // Botão de registro rápido apenas na aba Início
          floatingActionButton: _currentIndex == 0 && fazendaAtiva != null
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
              setState(() {
                _currentIndex = index;
              });
              // Ao voltar para o Início, atualiza o que foi registrado nas outras abas
              if (index == 0) _controller.loadActivities();
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
      case 1:
        return const FieldOperationPage();
      case 2:
        return const OperationPage();
      case 3:
        return const CostPage();
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

        if (state is CollaboratorHomeInitialState ||
            state is CollaboratorHomeLoadingState) {
          return const Center(child: CustomCircularProgressIndicator());
        }

        if (state is CollaboratorHomeNoFarmState) {
          return _buildMessageState(
            icon: Icons.home_work_outlined,
            title: 'Nenhuma fazenda vinculada',
            message:
                'Você ainda não foi vinculado a uma fazenda.\nPeça ao produtor para adicionar você em "Minha Equipe".',
          );
        }

        if (state is CollaboratorHomeErrorState) {
          return _buildMessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Algo deu errado',
            message: state.message,
            action: TextButton.icon(
              onPressed: () => _controller.loadActivities(reloadFarm: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          );
        }

        final successState = state as CollaboratorHomeSuccessState;

        return RefreshIndicator(
          color: AppColors.greenlightOne,
          onRefresh: () => _controller.loadActivities(reloadFarm: true),
          child: ListView(
            // Permite o "puxar para atualizar" mesmo com a lista vazia
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Text(
                  'Minhas Atividades',
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.greenlightOne,
                  ),
                ),
              ),
              if (successState.isEmpty)
                _buildEmptyActivitiesState()
              else
                ..._buildActivityCards(successState),
            ],
          ),
        );
      },
    );
  }

  // Junta operações e vistorias/aplicações, da mais recente para a mais antiga
  List<Widget> _buildActivityCards(CollaboratorHomeSuccessState state) {
    final combinedList = <({int timestamp, Widget widget})>[
      for (final op in state.operations)
        (timestamp: op.dateTimestamp, widget: _buildOperationCard(op)),
      for (final fOp in state.fieldOperations)
        (timestamp: fOp.dateTimestamp, widget: _buildFieldOperationCard(fOp)),
    ];

    combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return combinedList.map((e) => e.widget).toList();
  }

  Widget _buildOperationCard(OperationModel operation) {
    return OperationActivityCard(
      operation: operation,
      onTap: () => _openAndRefresh(OperationDetailsPage(operation: operation)),
    );
  }

  Widget _buildFieldOperationCard(FieldOperationModel fieldOperation) {
    return FieldOperationActivityCard(
      fieldOperation: fieldOperation,
      onTap: () =>
          _openAndRefresh(FieldOperationDetailsPage(operation: fieldOperation)),
    );
  }

  // Mostrado no primeiro acesso, enquanto o colaborador não registrou nada
  Widget _buildEmptyActivitiesState() {
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
            'Você ainda não registrou nenhuma operação, vistoria ou aplicação.\nUse o botão verde (+) para registrar sua primeira atividade!',
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

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.lightkGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}
