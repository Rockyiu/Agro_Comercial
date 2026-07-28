import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

class ChartOfAccountsPage extends StatelessWidget {
  ChartOfAccountsPage({super.key});

  // Nossa estrutura moderna e simplificada do Plano de Contas (agora com as contas 400 e 500 separadas)
  final List<Map<String, dynamic>> _planoDeContas = [
    {
      "codigo": "100",
      "titulo": "Receitas da Atividade Rural",
      "cor": Colors.blue[700],
      "subcontas": [
        {
          "codigo": "101",
          "nome": "Venda de Produtos Agrícolas (Grãos, Hortaliças)",
        },
        {"codigo": "102", "nome": "Venda de Produtos Pecuários (Gado, Leite)"},
        {"codigo": "103", "nome": "Venda de Subprodutos e Derivados"},
        {"codigo": "104", "nome": "Receitas de Arrendamento Rural"},
        {"codigo": "199", "nome": "Outras Receitas Rurais"},
      ],
    },
    {
      "codigo": "200",
      "titulo": "Despesas de Custeio e Investimento",
      "cor": AppColors.greenlightOne,
      "subcontas": [
        {
          "codigo": "201",
          "nome": "Insumos (Sementes, Fertilizantes, Defensivos)",
        },
        {"codigo": "202", "nome": "Combustíveis e Lubrificantes"},
        {"codigo": "203", "nome": "Manutenção de Maquinário e Implementos"},
        {
          "codigo": "204",
          "nome": "Folha de Pagamento e Encargos (Mão de Obra)",
        },
        {"codigo": "205", "nome": "Aquisição de Animais"},
        {"codigo": "206", "nome": "Compra de Tratores e Equipamentos"},
        {"codigo": "299", "nome": "Outras Despesas Dedutíveis"},
      ],
    },
    {
      "codigo": "300",
      "titulo": "Despesas Não Dedutíveis",
      "cor": Colors.red[600],
      "subcontas": [
        {"codigo": "301", "nome": "Multas e Juros de Mora"},
        {"codigo": "302", "nome": "Despesas Pessoais do Produtor"},
        {"codigo": "303", "nome": "Aquisição de Terra Nua"},
        {"codigo": "399", "nome": "Outras Despesas Não Dedutíveis"},
      ],
    },
    {
      "codigo": "400",
      "titulo": "Adiantamentos de Anos Anteriores",
      "cor": Colors.orange[700],
      "subcontas": [
        {
          "codigo": "401",
          "nome": "Recebidos até ano anterior p/ entrega neste ano",
        },
      ],
    },
    {
      "codigo": "500",
      "titulo": "Adiantamentos do Ano Atual",
      "cor": Colors.purple[600],
      "subcontas": [
        {"codigo": "501", "nome": "Recebidos neste ano para entrega futura"},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Plano de Contas",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.greenlightOne.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.greenlightOne),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Estas categorias serão usadas nos seus lançamentos para organizar os relatórios de consolidação.",
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _planoDeContas.length,
              itemBuilder: (context, index) {
                final contaPrincipal = _planoDeContas[index];
                final List<Map<String, String>> subcontas =
                    contaPrincipal['subcontas'] as List<Map<String, String>>;
                final corConta = contaPrincipal['cor'] as Color;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: corConta.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: ExpansionTile(
                    shape: const Border(),
                    leading: CircleAvatar(
                      backgroundColor: corConta.withValues(alpha: 0.1),
                      child: Icon(Icons.folder, color: corConta),
                    ),
                    title: Text(
                      "${contaPrincipal['codigo']} - ${contaPrincipal['titulo']}",
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: corConta,
                      ),
                    ),
                    children: subcontas.map((subconta) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.lightkGrey.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          leading: Text(
                            subconta['codigo']!,
                            style: AppTextStyles.smallText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey,
                            ),
                          ),
                          title: Text(
                            subconta['nome']!,
                            style: AppTextStyles.smallText,
                          ),
                          trailing: Icon(
                            Icons.subdirectory_arrow_left,
                            size: 16,
                            color: AppColors.lightkGrey.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
