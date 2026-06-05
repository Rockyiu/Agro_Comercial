import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(38.0),
      // Se o botão estiver desativado (onPressed == null), ele fica cinza
      color: onPressed == null ? AppColors.lightkGrey : null,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(38.0),
          // Garante que o degradê tenha exatamente as duas cores necessárias
          gradient: onPressed != null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.greenlightOne, // Cor principal
                    Color(
                      0xFF388E51,
                    ), // Verde escuro para o efeito de sombra/terra
                  ],
                )
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(38.0),
          onTap: onPressed,
          child: Container(
            alignment: Alignment.center,
            height: 56.0, // Altura confortável para o toque no celular
            child: Text(
              text,
              style: AppTextStyles.midText20.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
