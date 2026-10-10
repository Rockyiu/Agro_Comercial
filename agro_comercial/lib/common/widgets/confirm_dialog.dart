import 'package:agro_comercial/common/constants/app_colors.dart';
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
      icon: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: AppColors.dangerSoft,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 28,
        ),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.ink),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size(64, 50),
          ),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
