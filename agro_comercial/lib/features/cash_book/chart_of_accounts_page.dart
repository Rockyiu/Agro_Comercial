import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/chart_of_accounts.dart';
import 'package:flutter/material.dart';

class ChartOfAccountsPage extends StatelessWidget {
  const ChartOfAccountsPage({super.key});

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
              itemCount: ChartOfAccounts.groups.length,
              itemBuilder: (context, index) {
                final group = ChartOfAccounts.groups[index];
                final corConta = group.color;

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
                      "${group.code} - ${group.title}",
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: corConta,
                      ),
                    ),
                    children: group.accounts.map((subconta) {
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
                            subconta.code,
                            style: AppTextStyles.smallText.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey,
                            ),
                          ),
                          title: Text(
                            subconta.name,
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
