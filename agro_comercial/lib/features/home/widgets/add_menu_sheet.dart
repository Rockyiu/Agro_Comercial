import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:flutter/material.dart';

// Opção do menu aberto pelo botão "Registrar"
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
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
              ),
              for (var i = 0; i < options.length; i++)
                FadeSlideIn(
                  index: i,
                  child: _OptionTile(
                    option: options[i],
                    onTap: () {
                      Navigator.pop(sheetContext);
                      options[i].onTap();
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  final AddMenuOption option;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PressableScale(
        child: Material(
          color: AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(option.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
