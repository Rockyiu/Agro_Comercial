import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/logout_list_tile.dart';
import 'package:flutter/material.dart';

// Menu lateral: cabeçalho com a marca e a fazenda, itens e "Sair" no rodapé
class AppDrawer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> items;

  const AppDrawer({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldBackground(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(28),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBrandName(logoSize: 40),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: items,
            ),
          ),
          const Divider(indent: 24, endIndent: 24),
          const LogoutListTile(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Título de um grupo de itens do menu
class DrawerSection extends StatelessWidget {
  final String label;

  const DrawerSection(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppColors.inkMuted,
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.border,
        ),
        onTap: () {
          Navigator.pop(context); // Fecha o menu lateral
          onTap();
        },
      ),
    );
  }
}
