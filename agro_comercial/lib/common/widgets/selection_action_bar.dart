import 'package:agro_comercial/common/constants/app_colors.dart';
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
        color: AppColors.primarySoft,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: padding,
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Limpar seleção',
            icon: const Icon(Icons.close_rounded, color: AppColors.inkMuted),
            onPressed: onClear,
          ),
          IconButton.filledTonal(
            tooltip: 'Excluir',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.dangerSoft,
              foregroundColor: AppColors.danger,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
