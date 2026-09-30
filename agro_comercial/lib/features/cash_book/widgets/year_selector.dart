import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

// Seletor do ano-calendário do Livro Caixa (mesmo visual do filtro de mês)
class YearSelector extends StatelessWidget {
  final int year;
  final List<int> years;
  final ValueChanged<int> onChanged;

  const YearSelector({
    super.key,
    required this.year,
    required this.years,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greenlightOne.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          isExpanded: true,
          icon: const Icon(
            Icons.calendar_month,
            color: AppColors.greenlightOne,
          ),
          items: years
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text(
                    "Ano: $y",
                    style: AppTextStyles.inputText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
