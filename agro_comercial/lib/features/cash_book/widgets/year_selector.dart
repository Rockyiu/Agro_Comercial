import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Seletor do ano-calendário do Livro Caixa
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
      padding: const EdgeInsets.only(left: 14, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: year,
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.inkMuted,
                ),
                items: years
                    .map(
                      (y) => DropdownMenuItem(
                        value: y,
                        child: Text(
                          "Ano-calendário $y",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
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
          ),
        ],
      ),
    );
  }
}
