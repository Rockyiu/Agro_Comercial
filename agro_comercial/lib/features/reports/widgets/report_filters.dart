import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/area_unit_selector.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/surface_card.dart';
import 'package:flutter/material.dart';

import '../production_report.dart';
import '../reports_controller.dart';

// Abrangência, período, unidade de área e preço do diesel dos relatórios
class ReportFilters extends StatefulWidget {
  final ReportsController controller;

  const ReportFilters({super.key, required this.controller});

  @override
  State<ReportFilters> createState() => _ReportFiltersState();
}

class _ReportFiltersState extends State<ReportFilters> {
  late final _dieselController = TextEditingController(
    text: widget.controller.dieselPrice > 0
        ? Formatters.decimal(widget.controller.dieselPrice)
        : '',
  );

  ReportsController get _controller => widget.controller;

  @override
  void dispose() {
    _dieselController.dispose();
    super.dispose();
  }

  void _onDieselChanged(String text) {
    _controller.changeDieselPrice(Parsers.decimal(text) ?? 0);
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final current = ReportPeriod.currentCropYear(now);
    final options = <(String, IconData, ReportPeriod)>[
      (
        "Safra atual (${current.start.year}/${current.end.year})",
        Icons.wb_sunny_rounded,
        current,
      ),
      (
        "Safra anterior (${current.start.year - 1}/${current.end.year - 1})",
        Icons.history_rounded,
        ReportPeriod.cropYear(current.start.year - 1),
      ),
      (
        "Ano de ${now.year}",
        Icons.calendar_today_rounded,
        ReportPeriod.calendarYear(now.year),
      ),
      (
        "Ano de ${now.year - 1}",
        Icons.calendar_today_rounded,
        ReportPeriod.calendarYear(now.year - 1),
      ),
    ];

    final choice = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Text(
                  "Período do relatório",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
              ),
              for (final (label, icon, period) in options)
                _PeriodOption(
                  icon: icon,
                  title: label,
                  subtitle: period.label,
                  onTap: () => Navigator.pop(sheetContext, period),
                ),
              _PeriodOption(
                icon: Icons.edit_calendar_rounded,
                title: "Personalizado...",
                subtitle: "Escolha a data inicial e a final",
                onTap: () => Navigator.pop(sheetContext, 'custom'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice is ReportPeriod) {
      _controller.changePeriod(choice);
      return;
    }
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: _controller.period.start,
        end: _controller.period.end,
      ),
    );
    if (range != null) {
      _controller.changePeriod(ReportPeriod(range.start, range.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  "Filtros do relatório",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<ReportScope>(
              segments: const [
                ButtonSegment(
                  value: ReportScope.activeFarm,
                  label: Text("Fazenda ativa"),
                  icon: Icon(Icons.home_work_rounded),
                ),
                ButtonSegment(
                  value: ReportScope.allFarms,
                  label: Text("Todas"),
                  icon: Icon(Icons.public_rounded),
                ),
              ],
              selected: {_controller.scope},
              showSelectedIcon: false,
              onSelectionChanged: (s) => _controller.changeScope(s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.primary,
                selectedForegroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            SurfaceCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: _pickPeriod,
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.date_range_rounded,
                    size: 40,
                    color: AppColors.harvestDark,
                    background: AppColors.harvestSoft,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Período",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        Text(
                          _controller.period.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "Alterar",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AreaUnitSelector(
              label: "Exibir valores por",
              value: _controller.areaUnit,
              onChanged: _controller.changeAreaUnit,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dieselController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: _onDieselChanged,
              decoration: const InputDecoration(
                labelText: "Preço do diesel",
                prefixIcon: Icon(Icons.local_gas_station_rounded),
                prefixText: "R\$ ",
                suffixText: "/ litro",
                helperText: "Usado no custo de combustível das máquinas",
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PeriodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            size: 42,
            color: AppColors.primary,
            background: AppColors.primarySoft,
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}
