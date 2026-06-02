import 'package:flutter/material.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/locator.dart';

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

  void _handleSplashStateChange() {
    // Se o usuário estiver logado, vai para a Home, senão, vai para o Login
    if (_splashController.state is AuthenticatedUser) {
      Navigator.pushReplacementNamed(context, '/home');
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
            colors: AppColors.greenGradient, // Mantido o gradiente original
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Gestão Rural', // Trocado "financy" para o nome do seu projeto
              style: AppTextStyles.midText36.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Carregando...', // Traduzido
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
