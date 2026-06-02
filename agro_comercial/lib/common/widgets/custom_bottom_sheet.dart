import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

Future<void> customModalBottomSheet(
  BuildContext context, {
  required String content,
  required String buttonText,
  VoidCallback? onPressed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(38.0),
        topRight: Radius.circular(38.0),
      ),
    ),
    builder: (BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.iceWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(38.0),
            topRight: Radius.circular(38.0),
          ),
        ),
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  content, // Agora exibe o erro dinâmico do Firebase
                  textAlign: TextAlign.center,
                  style: AppTextStyles.midText20.copyWith(
                    color: AppColors.greenlightOne,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 32.0,
                ),
                child: PrimaryButton(
                  text: buttonText, // Agora exibe o texto dinâmico do botão
                  onPressed: onPressed ?? () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
