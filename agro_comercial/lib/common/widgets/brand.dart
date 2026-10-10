import 'dart:math' as math;

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Identidade visual: logo, fundo de lavoura e cabeçalhos em verde.

// Logo do Gestão Rural: broto sobre o verde da lavoura, com o sol da safra
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.3),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryLight, AppColors.primaryDark],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: size * 0.025,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.35),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: size * 0.58,
              ),
            ),
          ),
          // Sol da safra
          Positioned(
            right: -size * 0.08,
            top: -size * 0.08,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: AppColors.harvestGradient,
                ),
                border: Border.all(color: Colors.white, width: size * 0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Logo + nome do sistema
class AppBrandName extends StatelessWidget {
  final Color color;
  final double logoSize;
  final bool showTagline;

  const AppBrandName({
    super.key,
    this.color = Colors.white,
    this.logoSize = 44,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize),
        SizedBox(width: logoSize * 0.3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gestão Rural',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: logoSize * 0.46,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: color,
                height: 1.1,
              ),
            ),
            if (showTagline)
              Text(
                'GESTÃO DO AGRONEGÓCIO',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: logoSize * 0.21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: color.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Fundo verde com as linhas de plantio indo até o horizonte e o brilho do
// sol. Usado nos cabeçalhos e nas telas de entrada.
class FieldBackground extends StatelessWidget {
  final Widget? child;
  final BorderRadius? borderRadius;
  final bool showSun;

  const FieldBackground({
    super.key,
    this.child,
    this.borderRadius,
    this.showSun = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.brandGradient,
          ),
        ),
        child: CustomPaint(
          painter: _FieldPainter(showSun: showSun),
          child: child,
        ),
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  final bool showSun;

  _FieldPainter({required this.showSun});

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = Offset(size.width * 0.78, size.height * 0.08);

    if (showSun) {
      final sunRadius = math.max(size.width, size.height) * 0.42;
      canvas.drawCircle(
        horizon,
        sunRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.harvest.withValues(alpha: 0.26),
              AppColors.harvest.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: horizon, radius: sunRadius)),
      );
    }

    // Linhas de plantio saindo do horizonte em leque
    final rowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const rows = 22;
    for (var i = 0; i <= rows; i++) {
      final x = -size.width * 0.6 + (size.width * 2.2) * i / rows;
      final path = Path()
        ..moveTo(horizon.dx, horizon.dy)
        ..quadraticBezierTo(
          (horizon.dx + x) / 2 + size.width * 0.08,
          size.height * 0.6,
          x,
          size.height * 1.05,
        );
      canvas.drawPath(path, rowPaint);
    }

    // Faixa de terra na base, bem discreta
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.82, size.width, size.height * 0.18),
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.primaryDark.withValues(alpha: 0.35),
              ],
            ).createShader(
              Rect.fromLTWH(
                0,
                size.height * 0.82,
                size.width,
                size.height * 0.18,
              ),
            ),
    );
  }

  @override
  bool shouldRepaint(covariant _FieldPainter oldDelegate) =>
      oldDelegate.showSun != showSun;
}

// Etiqueta colorida (ex: "Safra 25/26", "Operação")
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Ícone dentro de um quadrado arredondado colorido (listas e menus)
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

// Título de seção: "Acesso rápido", "Atividades recentes"...
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: AppColors.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
