import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

// Aviso na parte de baixo da tela (ex: erro no login) com um botão de ação
Future<void> customModalBottomSheet(
  BuildContext context, {
  required String content,
  required String buttonText,
  VoidCallback? onPressed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.harvestSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.harvestDark,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: buttonText,
                onPressed: onPressed ?? () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}
