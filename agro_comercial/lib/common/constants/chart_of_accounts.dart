import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:flutter/material.dart';

// Plano de Contas do Livro Caixa (fonte única para a tela do plano e para os
// lançamentos). O primeiro dígito do código define a coluna da Consolidação.

class Account {
  final String code;
  final String name;

  const Account(this.code, this.name);

  // Texto salvo no lançamento, ex: "101 - Venda de Produtos Agrícolas..."
  String get label => "$code - $name";
}

class AccountGroup {
  final String code;
  final String title;
  final Color color;
  final List<Account> accounts;

  const AccountGroup({
    required this.code,
    required this.title,
    required this.color,
    required this.accounts,
  });
}

class ChartOfAccounts {
  ChartOfAccounts._();

  static const List<AccountGroup> groups = [
    AccountGroup(
      code: "100",
      title: "Receitas da Atividade Rural",
      color: AppColors.primary,
      accounts: [
        Account("101", "Venda de Produtos Agrícolas (Grãos, Hortaliças)"),
        Account("102", "Venda de Produtos Pecuários (Gado, Leite)"),
        Account("103", "Venda de Subprodutos e Derivados"),
        Account("104", "Receitas de Arrendamento Rural"),
        Account("199", "Outras Receitas Rurais"),
      ],
    ),
    AccountGroup(
      code: "200",
      title: "Despesas de Custeio e Investimento",
      color: AppColors.earth,
      accounts: [
        Account("201", "Insumos (Sementes, Fertilizantes, Defensivos)"),
        Account("202", "Combustíveis e Lubrificantes"),
        Account("203", "Manutenção de Maquinário e Implementos"),
        Account("204", "Folha de Pagamento e Encargos (Mão de Obra)"),
        Account("205", "Aquisição de Animais"),
        Account("206", "Compra de Tratores e Equipamentos"),
        Account("299", "Outras Despesas Dedutíveis"),
      ],
    ),
    AccountGroup(
      code: "300",
      title: "Despesas Não Dedutíveis",
      color: AppColors.danger,
      accounts: [
        Account("301", "Multas e Juros de Mora"),
        Account("302", "Despesas Pessoais do Produtor"),
        Account("303", "Aquisição de Terra Nua"),
        Account("399", "Outras Despesas Não Dedutíveis"),
      ],
    ),
    AccountGroup(
      code: "400",
      title: "Adiantamentos de Anos Anteriores",
      color: AppColors.harvestDark,
      accounts: [
        Account("401", "Recebidos até ano anterior p/ entrega neste ano"),
      ],
    ),
    AccountGroup(
      code: "500",
      title: "Adiantamentos do Ano Atual",
      color: AppColors.sky,
      accounts: [Account("501", "Recebidos neste ano para entrega futura")],
    ),
  ];

  static List<String> get accountLabels => [
    for (final group in groups)
      for (final account in group.accounts) account.label,
  ];
}
