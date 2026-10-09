import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

// Pergunta de confirmação padrão (ex: antes de excluir).
// Devolve true somente se o usuário confirmar.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = "Sim, excluir",
  String cancelText = "Cancelar",
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        title,
        style: AppTextStyles.midText20.copyWith(color: AppColors.greenlightOne),
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelText, style: const TextStyle(color: Colors.grey)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            confirmText,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
