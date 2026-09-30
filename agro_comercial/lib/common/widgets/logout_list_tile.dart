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
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: const Text(
        'Sair',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        Navigator.pop(context); // Fecha o menu lateral
        // Também apaga o usuário salvo no aparelho (senão o Splash
        // entraria direto na Home ao reabrir o app)
        await locator.get<AuthService>().signOut();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.signIn,
          (route) => false,
        );
      },
    );
  }
}
