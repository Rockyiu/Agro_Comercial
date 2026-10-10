import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:flutter/material.dart';

// Blocos do topo da Home: cartão da fazenda, indicadores e atalhos.

// Safra atual no formato "25/26" (a safra vai de julho a junho)
String currentCropYearLabel([DateTime? today]) {
  final now = today ?? DateTime.now();
  final start = now.month >= 7 ? now.year : now.year - 1;
  String short(int year) => (year % 100).toString().padLeft(2, '0');
  return "${short(start)}/${short(start + 1)}";
}

// Cartão verde com a fazenda ativa: safra, área, talhões e culturas
class FarmHeroCard extends StatelessWidget {
  final FarmModel farm;
  final VoidCallback? onTap;

  const FarmHeroCard({super.key, required this.farm, this.onTap});

  @override
  Widget build(BuildContext context) {
    final crops = {
      for (final plot in farm.plots)
        if (plot.crop.trim().isNotEmpty) plot.crop.trim(),
    };

    return PressableScale(
      enabled: onTap != null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FieldBackground(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(
                          label: 'Safra ${currentCropYearLabel()}',
                          icon: Icons.wb_sunny_rounded,
                          color: AppColors.onHarvest,
                          background: AppColors.harvest,
                        ),
                        const Spacer(),
                        if (onTap != null)
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      farm.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (farm.cadPro.isNotEmpty) 'CAD/PRO ${farm.cadPro}',
                        if (farm.address.isNotEmpty) farm.address,
                      ].join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        HeroMetric(
                          icon: Icons.straighten_rounded,
                          label: 'Área total',
                          value: farm.totalAreaLabel,
                        ),
                        HeroMetric(
                          icon: Icons.grid_view_rounded,
                          label: 'Talhões',
                          value: '${farm.plots.length}',
                        ),
                        HeroMetric(
                          icon: Icons.grass_rounded,
                          label: 'Culturas',
                          value: crops.isEmpty ? '-' : crops.join(', '),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Indicador numérico (ex: 12 operações)
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          // Número "contando" até o valor
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Text(
              double.tryParse(value) == null ? value : '${animated.round()}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });
}

// Grade de atalhos para as telas mais usadas
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsGrid({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 6 : 4;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < actions.length; i++)
              SizedBox(
                width: width,
                child: FadeSlideIn(
                  index: i,
                  child: _QuickActionTile(action: actions[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickAction action;

  const _QuickActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.94,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: action.onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: action.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
