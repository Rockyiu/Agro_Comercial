import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/page_hero.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'reports_controller.dart';
import 'reports_state.dart';
import 'widgets/management_dashboard.dart';
import 'widgets/report_export_card.dart';
import 'widgets/report_filters.dart';

// Aba "Relatórios" da Home: painel gerencial do custo de produção e geração
// dos relatórios em PDF
class ProductionReportsPage extends StatefulWidget {
  const ProductionReportsPage({super.key});

  @override
  State<ProductionReportsPage> createState() => _ProductionReportsPageState();
}

class _ProductionReportsPageState extends State<ProductionReportsPage> {
  final _controller = locator.get<ReportsController>();
  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _controller.loadPreferences();
    if (!mounted) return;
    setState(() => _preferencesLoaded = true);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_preferencesLoaded) {
      return const CustomCircularProgressIndicator();
    }

    return RefreshIndicator(
      onRefresh: () => _controller.load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          FadeSlideIn(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => _buildHero(),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(index: 1, child: ReportFilters(controller: _controller)),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final state = _controller.state;
    final total = state is ReportsSuccessState ? state.report.total : null;
    String money(double? value) =>
        value == null ? '...' : Formatters.currency(value);

    return PageHero(
      icon: Icons.insights_rounded,
      eyebrow: _controller.scope == ReportScope.allFarms
          ? 'Todas as fazendas'
          : 'Fazenda ativa',
      title: 'Custo de produção',
      subtitle: 'Período: ${_controller.period.label}',
      metrics: [
        HeroMetric(
          icon: Icons.payments_rounded,
          label: 'Custo total',
          value: money(total?.totalCost),
          scaleDown: true,
        ),
        HeroMetric(
          icon: Icons.sell_rounded,
          label: 'Receita',
          value: money(total?.revenue),
          scaleDown: true,
        ),
        HeroMetric(
          icon: Icons.trending_up_rounded,
          label: 'Margem',
          value: money(total?.margin),
          valueColor: (total?.margin ?? 0) < 0
              ? const Color(0xFFFFB4A9)
              : AppColors.harvest,
          scaleDown: true,
        ),
      ],
    );
  }

  Widget _buildContent() {
    final state = _controller.state;

    if (state is ReportsErrorState) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Algo deu errado',
        message: state.message,
        action: TextButton.icon(
          onPressed: () => _controller.load(forceRefresh: true),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    if (state is! ReportsSuccessState) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: CustomCircularProgressIndicator(),
      );
    }

    final report = state.report;
    final area = _controller.areaDisplay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.isEmpty)
          const EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'Sem lançamentos no período',
            message:
                'Registre operações, aplicações, custos e colheitas com o talhão para acompanhar o custo de produção aqui.',
          ),
        ManagementDashboard(report: report, area: area),
        const Padding(
          padding: EdgeInsets.only(top: 28, bottom: 12),
          child: SectionHeader(
            title: "Relatórios em PDF",
            subtitle: "Escolha os relatórios e o que fazer com eles",
          ),
        ),
        ReportExportCard(report: report, area: area),
      ],
    );
  }
}
