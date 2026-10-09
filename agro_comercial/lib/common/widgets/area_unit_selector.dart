import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:flutter/material.dart';

// Escolha da unidade de área (hectare ou alqueire) da fazenda e dos relatórios
class AreaUnitSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  final EdgeInsetsGeometry padding;

  const AreaUnitSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = "UNIDADE DE ÁREA",
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: AppTextStyles.smallText.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.greenlightOne,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: AreaUnits.labels.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.greenlightOne,
              selectedForegroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
