import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';

// Estrutura das telas de entrada (login, cadastro, senha): cabeçalho verde
// com a lavoura e a marca, e o conteúdo num painel branco por cima.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Key? scrollKey;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.scrollKey,
  });

  static const _sheetOverlap = 32.0;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        key: scrollKey,
        padding: EdgeInsets.zero,
        children: [
          FieldBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  _sheetOverlap + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 48,
                      child: canPop
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const FadeSlideIn(child: AppBrandName(logoSize: 46)),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      index: 2,
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Painel branco subindo por cima do cabeçalho
          Transform.translate(
            offset: const Offset(0, -_sheetOverlap),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.only(top: 20, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeSlideIn(
                    index: 3,
                    offsetY: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Link de texto em duas partes: "Não tem uma conta? Cadastre-se"
class AuthSwitchLink extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onPressed;

  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text.rich(
        TextSpan(
          text: '$question ',
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(
              text: action,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
