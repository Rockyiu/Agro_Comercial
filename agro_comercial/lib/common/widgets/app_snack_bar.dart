import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Atalhos para os avisos rápidos usados em todo o app
extension AppSnackBar on BuildContext {
  void showErrorSnackBar(String message) => _show(message, Colors.red);

  void showSuccessSnackBar(String message) =>
      _show(message, AppColors.greenlightOne);

  void showWarningSnackBar(String message) => _show(message, Colors.orange);

  void _show(String message, Color color) {
    ScaffoldMessenger.of(
      this,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}
