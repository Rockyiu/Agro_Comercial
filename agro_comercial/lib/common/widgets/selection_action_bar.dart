import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

// Barra exibida no modo de seleção múltipla das listas:
// "N selecionado(s)" + botões para limpar a seleção e excluir os itens
class SelectionActionBar extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;

  const SelectionActionBar({
    super.key,
    required this.label,
    required this.onClear,
    required this.onDelete,
    this.borderRadius,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.greenlightOne.withValues(alpha: 0.1),
        borderRadius: borderRadius,
      ),
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.inputText.copyWith(
              color: AppColors.greenlightOne,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.grey),
                onPressed: onClear,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
