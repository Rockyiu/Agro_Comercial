import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'reports_controller.dart';
import 'reports_state.dart';
import 'widgets/management_dashboard.dart';
import 'widgets/report_export_card.dart';
import 'widgets/report_filters.dart';

// Aba "Relatório" da Home: painel gerencial do custo de produção e geração
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
      return const Center(child: CustomCircularProgressIndicator());
    }

    return RefreshIndicator(
      color: AppColors.greenlightOne,
      onRefresh: () => _controller.load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text(
              'Custo de Produção',
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
          ),
          ReportFilters(controller: _controller),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final state = _controller.state;

    if (state is ReportsErrorState) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Algo deu errado',
        message: state.message,
        action: TextButton.icon(
          onPressed: () => _controller.load(forceRefresh: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    if (state is! ReportsSuccessState) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CustomCircularProgressIndicator()),
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
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            "Relatórios em PDF",
            style: AppTextStyles.midText18.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
        ),
        ReportExportCard(report: report, area: area),
      ],
    );
  }
}
