import 'package:flutter/material.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
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
    _splashController.addListener(_handleSplashStateChange);
    _splashController.isUserLogged();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  void _handleSplashStateChange() {
    final state = _splashController.state;

    if (state is AuthenticatedUser) {
      // Colaborador e produtor têm telas iniciais diferentes
      Navigator.pushReplacementNamed(
        context,
        state.isCollaborator ? NamedRoute.collaboratorHome : NamedRoute.home,
      );
    } else if (state is UnauthenticatedUser) {
      Navigator.pushReplacementNamed(context, NamedRoute.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo surgindo com um leve "crescimento", como um broto
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Opacity(
                  opacity: value.clamp(0, 1).toDouble(),
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * value,
                    child: child,
                  ),
                ),
                child: const AppLogo(size: 96),
              ),
              const SizedBox(height: 28),
              const FadeSlideIn(
                delay: Duration(milliseconds: 300),
                child: Text(
                  'Gestão Rural',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: Text(
                  'GESTÃO DO AGRONEGÓCIO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    color: AppColors.harvest,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tecnologia para o agro brasileiro',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
