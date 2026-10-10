import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:flutter/material.dart';

// Cartão branco das listas: borda suave, "afunda" ao toque e fica verde
// quando selecionado (seleção múltipla)
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: margin,
      child: PressableScale(
        enabled: onTap != null || onLongPress != null,
        child: Material(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// Opção de saída (Visualizar, Gerar PDF, Imprimir): fica verde quando escolhida
class OptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return PressableScale(
      pressedScale: 0.95,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primary],
                    )
                  : null,
              color: selected ? null : AppColors.surface,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: selected ? Colors.white : AppColors.inkMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink,
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

// Item marcável (ex: qual relatório incluir no PDF)
class CheckCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const CheckCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      selected: value,
      onTap: () => onChanged(!value),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? AppColors.primary : AppColors.border,
                width: 1.6,
              ),
            ),
            child: AnimatedScale(
              scale: value ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 10),
            Icon(
              icon,
              size: 20,
              color: value ? AppColors.primary : AppColors.inkMuted,
            ),
          ],
        ],
      ),
    );
  }
}
