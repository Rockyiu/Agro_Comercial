import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

import 'taxpayer_identification_page.dart';
import 'chart_of_accounts_page.dart';
import 'bookkeeping_page.dart';
import 'consolidation_page.dart';
import 'reports_page.dart';

class CashBookPage extends StatelessWidget {
  const CashBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
          child: Text(
            'Módulos do Livro Caixa',
            style: AppTextStyles.midText20.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
        ),

        // Botão 1: Identificação
        _buildMenuCard(
          context,
          title: 'Identificação do Contribuinte',
          subtitle: 'Dados do produtor e imóveis rurais explorados',
          icon: Icons.person_search,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TaxpayerIdentificationPage(),
              ),
            );
          },
        ),

        // Botão 2: Escrituração
        _buildMenuCard(
          context,
          title: 'Escrituração',
          subtitle: 'Lançamentos de receitas e despesas',
          icon: Icons.edit_document,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookkeepingPage()),
            );
          },
        ),

        // Botão 3: Plano de Contas
        _buildMenuCard(
          context,
          title: 'Plano de Contas',
          subtitle: 'Categorias de receitas e despesas rurais',
          icon: Icons.account_tree,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChartOfAccountsPage(),
              ),
            );
          },
        ),

        _buildMenuCard(
          context,
          title: 'Consolidação (Resumo)',
          subtitle: 'Tabela de fechamento mensal e resultados',
          icon: Icons.table_chart,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ConsolidationPage(),
              ),
            );
          },
        ),
        _buildMenuCard(
          context,
          title: 'Demonstrativos',
          subtitle: 'Imprimir e Exportar Relatórios (PDF)',
          icon: Icons.print,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.greenlightOne.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.greenlightOne),
        ),
        title: Text(
          title,
          style: AppTextStyles.inputText.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: AppTextStyles.smallText),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.lightkGrey,
        ),
        onTap: onTap,
      ),
    );
  }
}
