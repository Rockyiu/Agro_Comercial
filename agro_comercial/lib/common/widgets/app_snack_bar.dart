import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Atalhos para os avisos rápidos usados em todo o app
extension AppSnackBar on BuildContext {
  void showErrorSnackBar(String message) =>
      _show(message, AppColors.danger, Icons.error_outline_rounded);

  void showSuccessSnackBar(String message) =>
      _show(message, AppColors.primary, Icons.check_circle_outline_rounded);

  void showWarningSnackBar(String message) =>
      _show(message, AppColors.warning, Icons.warning_amber_rounded);

  void _show(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
