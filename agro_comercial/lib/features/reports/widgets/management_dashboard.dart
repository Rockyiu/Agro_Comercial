import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
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

  static const _negative = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final total = report.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.warnings.messages.isNotEmpty) _buildWarnings(),
        _sectionTitle("Painel gerencial"),
        _SummaryMetrics(summary: total, area: area),
        if (total.costByGroup.isNotEmpty) ...[
          _sectionTitle("Composição do custo"),
          _buildCostComposition(total),
        ],
        _sectionTitle("Resultado por talhão"),
        if (report.plots.isEmpty)
          const Text("Nenhum talhão cadastrado.")
        else
          for (final plot in report.plots) _buildSummaryTile(plot.summary),
        if (report.byCrop.isNotEmpty) ...[
          _sectionTitle("Resumo por cultura"),
          for (final s in report.byCrop) _buildSummaryTile(s),
        ],
        if (report.byFarm.length > 1) ...[
          _sectionTitle("Resumo por propriedade"),
          for (final s in report.byFarm) _buildSummaryTile(s),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: AppTextStyles.midText18.copyWith(color: AppColors.greenlightOne),
      ),
    );
  }

  Widget _buildWarnings() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.amber.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.shade700),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Dados para completar",
                    style: AppTextStyles.smallText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final message in report.warnings.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "• $message",
                  style: AppTextStyles.smallText.copyWith(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostComposition(CostSummary summary) {
    final total = summary.totalCost;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final entry in summary.sortedGroups)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key.label,
                            style: AppTextStyles.smallText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "${Formatters.currency(entry.value)}  "
                            "(${Formatters.decimal(entry.value / total * 100)}%)",
                            textAlign: TextAlign.end,
                            style: AppTextStyles.smallText.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: total > 0 ? entry.value / total : 0,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      color: AppColors.greenlightOne,
                      backgroundColor: AppColors.greenlightOne.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(CostSummary s) {
    final marginColor = s.margin < 0 ? _negative : AppColors.greenlightOne;
    final details = [
      "${Formatters.decimal(area.area(s.areaHa))} ${area.label}",
      Formatters.currency(s.totalCost),
      "${Formatters.currency(area.perArea(s.costPerHa))}/${area.label}",
    ].join("  •  ");

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          s.name,
          style: AppTextStyles.smallText.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          s.subtitle.isEmpty ? details : "${s.subtitle}\n$details",
          style: AppTextStyles.smallText.copyWith(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Margem",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              Formatters.currency(s.margin),
              style: AppTextStyles.smallText.copyWith(
                color: marginColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [_SummaryMetrics(summary: s, area: area, compact: true)],
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
    final metrics = <(String, String, Color?)>[
      (
        "Área",
        "${Formatters.decimal(area.area(s.areaHa))} ${area.label}",
        null,
      ),
      ("Custo total", Formatters.currency(s.totalCost), null),
      ("Custo$perArea", Formatters.currency(area.perArea(s.costPerHa)), null),
      ("Produção", s.production.format(), null),
      (
        "Produtividade",
        s.productivityPerHa == null
            ? '-'
            : "${Formatters.decimal(area.perArea(s.productivityPerHa!))} $unit$perArea",
        null,
      ),
      ("Receita", Formatters.currency(s.revenue), null),
      (
        "Margem",
        Formatters.currency(s.margin),
        s.margin < 0 ? ManagementDashboard._negative : AppColors.greenlightOne,
      ),
      (
        "Margem$perArea",
        Formatters.currency(area.perArea(s.marginPerHa)),
        s.margin < 0 ? ManagementDashboard._negative : null,
      ),
      (
        "Custo por ${unit ?? 'unidade'}",
        s.costPerUnit == null ? '-' : Formatters.currency(s.costPerUnit!),
        null,
      ),
      (
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
            for (final (label, value, color) in metrics)
              SizedBox(
                width: width,
                child: _MetricTile(
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
  final String label;
  final String value;
  final Color? color;
  final bool compact;

  const _MetricTile({
    required this.label,
    required this.value,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: compact
            ? AppColors.greenlightOne.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: compact
            ? null
            : const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.smallText.copyWith(
              fontSize: 11,
              color: AppColors.lightkGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 15,
              color: color ?? AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
