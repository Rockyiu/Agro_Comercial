import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';

// Apresentação do app para quem ainda não tem conta
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _features = [
    (
      icon: Icons.agriculture_rounded,
      title: 'Operações e maquinário',
      text: 'Plantio, aplicações, horímetro e custo da hora-máquina.',
    ),
    (
      icon: Icons.inventory_2_rounded,
      title: 'Estoque de insumos',
      text: 'Sementes, defensivos e fertilizantes sempre atualizados.',
    ),
    (
      icon: Icons.insights_rounded,
      title: 'Custo de produção',
      text: 'Relatórios por talhão, por safra e o Livro Caixa do produtor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FieldBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: [
                  const FadeSlideIn(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AppBrandName(logoSize: 48),
                    ),
                  ),
                  const SizedBox(height: 48),
                  const FadeSlideIn(
                    index: 1,
                    child: Text(
                      'O agro na palma da sua mão.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                        height: 1.1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 2,
                    child: Text(
                      'Da porteira para dentro: lavoura, equipe, estoque e custos '
                      'da sua fazenda em um só lugar.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  for (var i = 0; i < _features.length; i++)
                    FadeSlideIn(
                      index: 3 + i,
                      child: _FeatureTile(
                        icon: _features[i].icon,
                        title: _features[i].title,
                        text: _features[i].text,
                      ),
                    ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    index: 7,
                    child: PressableScale(
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/sign_up'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.harvest,
                          foregroundColor: AppColors.onHarvest,
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Começar agora'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 8,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/sign_in'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.4,
                        ),
                      ),
                      child: const Text('Já tenho conta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.harvest.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.harvest),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
