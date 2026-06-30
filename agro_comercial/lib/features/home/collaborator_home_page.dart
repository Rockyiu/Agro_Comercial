import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_page.dart';
import 'package:agro_comercial/features/operation/operation_page.dart';
import 'package:agro_comercial/features/profile/profile_page.dart';
import 'package:agro_comercial/features/sign_in/sign_in_page.dart';
import 'package:agro_comercial/locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CollaboratorHomePage extends StatefulWidget {
  const CollaboratorHomePage({super.key});

  @override
  State<CollaboratorHomePage> createState() => _CollaboratorHomePageState();
}

class _CollaboratorHomePageState extends State<CollaboratorHomePage> {
  int _currentIndex = 0;

  // As três abas do colaborador (Vistorias, Operações e Em Breve)
  final List<Widget> _pages = [
    const FieldOperationPage(),
    const OperationPage(),
    const Center(child: Text("Nova funcionalidade em breve")), // Terceira aba
  ];

  @override
  Widget build(BuildContext context) {
    // Pega a fazenda ativa para mostrar no Drawer
    final farmController = locator.get<FarmController>();
    final fazendaAtiva = farmController.selectedFarm;

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
                                color: Colors.white.withOpacity(0.2),
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
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),

      // CORPO (PÁGINAS)
      body: _pages[_currentIndex],

      // BOTTOM NAVIGATION (APENAS 3 OPÇÕES, SEM BOTÃO CENTRAL)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.greenlightOne,
        unselectedItemColor: AppColors.lightkGrey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in_outlined),
            label: 'Vistorias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Operações',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
