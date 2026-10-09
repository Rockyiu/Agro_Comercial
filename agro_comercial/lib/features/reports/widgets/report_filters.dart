import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/area_unit_selector.dart';
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
    final options = <(String, ReportPeriod)>[
      ("Safra atual (${current.start.year}/${current.end.year})", current),
      (
        "Safra anterior (${current.start.year - 1}/${current.end.year - 1})",
        ReportPeriod.cropYear(current.start.year - 1),
      ),
      ("Ano de ${now.year}", ReportPeriod.calendarYear(now.year)),
      ("Ano de ${now.year - 1}", ReportPeriod.calendarYear(now.year - 1)),
    ];

    final choice = await showModalBottomSheet<Object>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Período do relatório",
                style: AppTextStyles.midText18.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
            ),
            for (final (label, period) in options)
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text(label),
                subtitle: Text(period.label),
                onTap: () => Navigator.pop(sheetContext, period),
              ),
            ListTile(
              leading: const Icon(Icons.edit_calendar),
              title: const Text("Personalizado..."),
              onTap: () => Navigator.pop(sheetContext, 'custom'),
            ),
          ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ReportScope>(
                segments: const [
                  ButtonSegment(
                    value: ReportScope.activeFarm,
                    label: Text("Fazenda ativa"),
                    icon: Icon(Icons.home_work_outlined),
                  ),
                  ButtonSegment(
                    value: ReportScope.allFarms,
                    label: Text("Todas"),
                    icon: Icon(Icons.public),
                  ),
                ],
                selected: {_controller.scope},
                onSelectionChanged: (s) => _controller.changeScope(s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.greenlightOne,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickPeriod,
                icon: const Icon(
                  Icons.date_range,
                  color: AppColors.greenlightOne,
                ),
                label: Text(
                  "Período: ${_controller.period.label}",
                  style: const TextStyle(color: AppColors.greenlightOne),
                ),
              ),
              const SizedBox(height: 12),
              AreaUnitSelector(
                label: "EXIBIR VALORES POR",
                value: _controller.areaUnit,
                onChanged: _controller.changeAreaUnit,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dieselController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: _onDieselChanged,
                decoration: const InputDecoration(
                  labelText: "PREÇO DO DIESEL",
                  prefixText: "R\$ ",
                  suffixText: "/ litro",
                  helperText: "Usado no custo de combustível das máquinas",
                  isDense: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.greenlightOne),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.greenlightOne,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
