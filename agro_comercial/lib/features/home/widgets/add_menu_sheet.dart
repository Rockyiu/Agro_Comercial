import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

// Opção do menu aberto pelo botão verde (+)
class AddMenuOption {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AddMenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

// Menu inferior com as opções de cadastro. O menu é fechado antes de
// executar a opção escolhida.
void showAddMenuSheet(
  BuildContext context, {
  required String title,
  required List<AddMenuOption> options,
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: AppColors.iceWhite,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.midText20.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
              const SizedBox(height: 24),
              for (final option in options)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(option.icon, color: AppColors.greenlightOne),
                  ),
                  title: Text(option.title, style: AppTextStyles.inputText),
                  subtitle: Text(
                    option.subtitle,
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.lightkGrey,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    option.onTap();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
