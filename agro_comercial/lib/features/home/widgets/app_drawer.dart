import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/logout_list_tile.dart';
import 'package:flutter/material.dart';

// Estrutura do menu lateral: cabeçalho verde + itens + botão "Sair" no rodapé
class AppDrawer extends StatelessWidget {
  final Widget header;
  final List<Widget> items;

  const AppDrawer({super.key, required this.header, required this.items});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.iceWhite,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: AppColors.greenlightOne,
                  ),
                  child: Align(alignment: Alignment.bottomLeft, child: header),
                ),
                ...items,
              ],
            ),
          ),
          const Divider(),
          const LogoutListTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Item do menu lateral: fecha o menu e executa a ação
class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.greenlightOne),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Fecha o menu lateral
        onTap();
      },
    );
  }
}
