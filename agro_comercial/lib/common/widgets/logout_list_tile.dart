import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';
import 'package:flutter/material.dart';

// Botão "Sair" dos menus laterais (produtor e colaborador)
class LogoutListTile extends StatelessWidget {
  const LogoutListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
      title: const Text(
        'Sair da conta',
        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
      ),
      onTap: () async {
        // O Navigator é guardado antes: ao fechar o menu lateral este item sai
        // da tela, e o contexto dele não serve mais para navegar
        final navigator = Navigator.of(context);
        navigator.pop(); // Fecha o menu lateral
        // Também apaga o usuário salvo no aparelho (senão o Splash
        // entraria direto na Home ao reabrir o app)
        await locator.get<AuthService>().signOut();
        await resetUserSession();
        navigator.pushNamedAndRemoveUntil(NamedRoute.signIn, (route) => false);
      },
    );
  }
}
