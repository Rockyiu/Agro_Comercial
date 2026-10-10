import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';

// Faixa verde do topo das abas (Livro Caixa, Armazém, Relatórios): ícone,
// título, descrição e alguns números de destaque
class PageHero extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<HeroMetric> metrics;
  final Widget? action;

  const PageHero({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.metrics = const [],
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBadge(
                    icon: icon,
                    size: 46,
                    color: AppColors.harvest,
                    background: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            color: AppColors.harvest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
              if (metrics.isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(children: metrics),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}

// Número de destaque sobre o fundo verde (ex: "Área total  120 ha")
class HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  // Diminui o texto para caber (valores em reais) em vez de cortar com "..."
  final bool scaleDown;

  const HeroMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.scaleDown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.harvest),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _value(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _value() {
    final text = Text(
      value,
      maxLines: 1,
      overflow: scaleDown ? null : TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: valueColor ?? Colors.white,
      ),
    );
    return Align(
      key: ValueKey(value),
      alignment: Alignment.centerLeft,
      child: scaleDown ? FittedBox(fit: BoxFit.scaleDown, child: text) : text,
    );
  }
}
