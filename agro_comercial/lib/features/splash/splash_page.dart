import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/locator.dart';

// ADICIONADO: Importe a tela do colaborador
import 'package:agro_comercial/features/home/collaborator_home_page.dart';

import 'splash_controller.dart';
import 'splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _splashController = locator.get<SplashController>();

  @override
  void initState() {
    super.initState();
    _splashController.isUserLogged();
    _splashController.addListener(_handleSplashStateChange);
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  Future<void> _handleSplashStateChange() async {
    if (_splashController.state is AuthenticatedUser) {
      // VERIFICA SE É COLABORADOR OU ADMIN ANTES DE NAVEGAR
      try {
        final user = FirebaseAuth.instance.currentUser;
        bool isCollaborator = false;

        if (user != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final data = doc.data();

          if (data != null) {
            if (data['role'] == 'colaborador' ||
                data['tipo'] == 'colaborador') {
              isCollaborator = true;
            }
          }
        }

        if (!mounted) return;

        if (isCollaborator) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CollaboratorHomePage(),
            ),
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        // Em caso de erro de conexão, manda para a tela padrão por segurança
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else if (_splashController.state is UnauthenticatedUser) {
      Navigator.pushReplacementNamed(context, '/sign_in');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.greenGradient,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Gestão Rural',
              style: AppTextStyles.midText36.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Carregando...',
              style: AppTextStyles.smallText.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24.0),
            const CustomCircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
