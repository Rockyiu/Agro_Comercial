import 'dart:math' as math;

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/cost_categories.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';

import '../production_report.dart';

// Painel gerencial: indicadores do conjunto, composição do custo e o resultado
// de cada talhão, cultura e propriedade
class ManagementDashboard extends StatelessWidget {
  final ProductionReport report;
  final AreaDisplay area;

  const ManagementDashboard({
    super.key,
    required this.report,
    required this.area,
  });

  @override
  Widget build(BuildContext context) {
    final total = report.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.warnings.messages.isNotEmpty) _buildWarnings(),
        _sectionTitle("Painel gerencial", "Indicadores do período"),
        FadeSlideIn(
          child: _SummaryMetrics(summary: total, area: area),
        ),
        if (total.costByGroup.isNotEmpty) ...[
          _sectionTitle("Composição do custo", "Para onde foi o dinheiro"),
          FadeSlideIn(child: _CostComposition(summary: total)),
        ],
        _sectionTitle("Resultado por talhão", "Toque para ver os detalhes"),
        if (report.plots.isEmpty)
          const Text(
            "Nenhum talhão cadastrado.",
            style: TextStyle(fontFamily: 'Inter', color: AppColors.inkMuted),
          )
        else
          for (var i = 0; i < report.plots.length; i++)
            FadeSlideIn(
              index: i,
              child: _SummaryTile(
                summary: report.plots[i].summary,
                area: area,
                icon: Icons.grid_view_rounded,
                color: AppColors.primary,
                background: AppColors.primarySoft,
              ),
            ),
        if (report.byCrop.isNotEmpty) ...[
          _sectionTitle("Resumo por cultura"),
          for (final s in report.byCrop)
            _SummaryTile(
              summary: s,
              area: area,
              icon: Icons.grass_rounded,
              color: AppColors.harvestDark,
              background: AppColors.harvestSoft,
            ),
        ],
        if (report.byFarm.length > 1) ...[
          _sectionTitle("Resumo por propriedade"),
          for (final s in report.byFarm)
            _SummaryTile(
              summary: s,
              area: area,
              icon: Icons.landscape_rounded,
              color: AppColors.earth,
              background: AppColors.earthSoft,
            ),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text, [String? subtitle]) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: SectionHeader(title: text, subtitle: subtitle),
    );
  }

  Widget _buildWarnings() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.harvestSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.harvest.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.lightbulb_rounded,
            size: 38,
            color: AppColors.onHarvest,
            background: AppColors.harvest,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dados para completar",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onHarvest,
                  ),
                ),
                const SizedBox(height: 6),
                for (final message in report.warnings.messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• $message",
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.ink,
                      ),
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

// Cores das fatias do gráfico (paleta do agro)
const _sliceColors = [
  AppColors.primary,
  AppColors.harvest,
  AppColors.earth,
  AppColors.sky,
  AppColors.water,
  AppColors.primaryLight,
  AppColors.harvestDark,
  Color(0xFF6D8B3A), // verde-oliva
  Color(0xFFB5651D), // terracota
  Color(0xFF7A8C99), // cinza-azulado
];

Color _sliceColor(int index) => _sliceColors[index % _sliceColors.length];

// Gráfico de rosca + legenda com valor e porcentagem de cada grupo
class _CostComposition extends StatelessWidget {
  final CostSummary summary;

  const _CostComposition({required this.summary});

  @override
  Widget build(BuildContext context) {
    final groups = summary.sortedGroups;
    final total = summary.totalCost;

    final donut = SizedBox.square(
      dimension: 168,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => CustomPaint(
          painter: _DonutPainter(
            values: [for (final g in groups) g.value],
            progress: t,
          ),
          child: child,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Custo total",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.inkMuted,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    Formatters.currency(total),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final legend = Column(
      children: [
        for (var i = 0; i < groups.length; i++)
          _LegendRow(
            group: groups[i].key,
            value: groups[i].value,
            share: total > 0 ? groups[i].value / total : 0,
            color: _sliceColor(i),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                donut,
                const SizedBox(width: 24),
                Expanded(child: legend),
              ],
            );
          }
          return Column(children: [donut, const SizedBox(height: 16), legend]);
        },
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final ExpenseGroup group;
  final double value;
  final double share;
  final Color color;

  const _LegendRow({
    required this.group,
    required this.value,
    required this.share,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                Formatters.currency(value),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  "${Formatters.decimal(share * 100)}%",
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra que cresce até a fatia do grupo
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: share),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double progress;

  _DonutPainter({required this.values, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (sum, v) => sum + v);
    const stroke = 22.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - stroke / 2,
    );

    // Trilho de fundo
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.surfaceMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (total <= 0) return;

    // Fatias, com um pequeno espaço entre elas
    final gap = values.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    final available = math.pi * 2 * progress;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      final visible = math.min(sweep, available - (start + math.pi / 2));
      if (visible <= 0) break;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(visible - gap, 0.001),
        false,
        Paint()
          ..color = _sliceColor(i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.values != values;
}

// Talhão, cultura ou propriedade: margem em destaque e indicadores ao abrir
class _SummaryTile extends StatelessWidget {
  final CostSummary summary;
  final AreaDisplay area;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryTile({
    required this.summary,
    required this.area,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final negative = s.margin < 0;
    final details = [
      "${Formatters.decimal(area.area(s.areaHa))} ${area.label}",
      "${Formatters.currency(area.perArea(s.costPerHa))}/${area.label}",
    ].join("  •  ");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: IconBadge(icon: icon, color: color, background: background),
          title: Text(
            s.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: Text(
            s.subtitle.isEmpty ? details : "${s.subtitle}\n$details",
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.inkMuted,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Margem",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 2),
              StatusChip(
                label: Formatters.currency(s.margin),
                color: negative ? AppColors.danger : AppColors.primary,
                background: negative
                    ? AppColors.dangerSoft
                    : AppColors.primarySoft,
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: [_SummaryMetrics(summary: s, area: area, compact: true)],
        ),
      ),
    );
  }
}

// Indicadores de um resumo: custo, produção, receita, margem e custo/unidade
class _SummaryMetrics extends StatelessWidget {
  final CostSummary summary;
  final AreaDisplay area;
  final bool compact;

  const _SummaryMetrics({
    required this.summary,
    required this.area,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final unit = s.production.unit;
    final perArea = "/${area.label}";
    final marginColor = s.margin < 0 ? AppColors.danger : AppColors.primary;
    final metrics = <(IconData, String, String, Color?)>[
      (
        Icons.straighten_rounded,
        "Área",
        "${Formatters.decimal(area.area(s.areaHa))} ${area.label}",
        null,
      ),
      (
        Icons.payments_rounded,
        "Custo total",
        Formatters.currency(s.totalCost),
        null,
      ),
      (
        Icons.square_foot_rounded,
        "Custo$perArea",
        Formatters.currency(area.perArea(s.costPerHa)),
        null,
      ),
      (Icons.grass_rounded, "Produção", s.production.format(), null),
      (
        Icons.speed_rounded,
        "Produtividade",
        s.productivityPerHa == null
            ? '-'
            : "${Formatters.decimal(area.perArea(s.productivityPerHa!))} $unit$perArea",
        null,
      ),
      (Icons.sell_rounded, "Receita", Formatters.currency(s.revenue), null),
      (
        Icons.trending_up_rounded,
        "Margem",
        Formatters.currency(s.margin),
        marginColor,
      ),
      (
        Icons.area_chart_rounded,
        "Margem$perArea",
        Formatters.currency(area.perArea(s.marginPerHa)),
        s.margin < 0 ? AppColors.danger : null,
      ),
      (
        Icons.calculate_rounded,
        "Custo por ${unit ?? 'unidade'}",
        s.costPerUnit == null ? '-' : Formatters.currency(s.costPerUnit!),
        null,
      ),
      (
        Icons.balance_rounded,
        "Ponto de equilíbrio",
        s.breakEvenPerHa == null
            ? '-'
            : "${Formatters.decimal(area.perArea(s.breakEvenPerHa!))} $unit$perArea",
        null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 5 : 2;
        const spacing = 8.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final (icon, label, value, color) in metrics)
              SizedBox(
                width: width,
                child: _MetricTile(
                  icon: icon,
                  label: label,
                  value: value,
                  color: color,
                  compact: compact,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool compact;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: compact ? AppColors.background : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: compact ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.primaryLight),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: compact ? 13.5 : 15.5,
                color: color ?? AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
