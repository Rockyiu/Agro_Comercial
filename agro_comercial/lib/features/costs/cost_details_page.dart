import 'package:flutter/material.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/cost_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/locator.dart';

import 'cost_controller.dart';

import 'register_cost_page.dart';

class CostDetailsPage extends StatefulWidget {
  final CostModel cost;

  const CostDetailsPage({super.key, required this.cost});

  @override
  State<CostDetailsPage> createState() => _CostDetailsPageState();
}

class _CostDetailsPageState extends State<CostDetailsPage> {
  final _costController = locator.get<CostController>();
  bool _isCollaborator = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  @override
  void dispose() {
    _costController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    final isCollaborator = await _costController.isCurrentUserCollaborator();
    if (mounted) setState(() => _isCollaborator = isCollaborator);
  }

  @override
  Widget build(BuildContext context) {
    // Regra de segurança: Esconde o botão de editar se for colaborador E o custo for mão de obra
    final showEditButton = !(_isCollaborator && widget.cost.isLabor);

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Detalhes do Custo",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (showEditButton)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegisterCostPage(costToEdit: widget.cost),
                  ),
                );
                // Se retornar true, significa que editou ou excluiu. Fechamos esta tela para a lista recarregar.
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CATEGORIA",
                  style: TextStyle(
                    color: AppColors.greenlightOne,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(widget.cost.category, style: AppTextStyles.midText20),
                const Divider(height: 32),

                Text(
                  "TIPO DE CUSTO",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(widget.cost.type, style: AppTextStyles.inputText),
                const SizedBox(height: 16),

                Text(
                  "DATA DO LANÇAMENTO",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  Formatters.date(widget.cost.dateTimestamp),
                  style: AppTextStyles.inputText,
                ),
                const SizedBox(height: 16),

                Text(
                  "TALHÃO",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  (widget.cost.plotName?.isNotEmpty ?? false)
                      ? widget.cost.plotName!
                      : "Fazenda inteira (rateio por área)",
                  style: AppTextStyles.inputText,
                ),
                const SizedBox(height: 16),

                if (widget.cost.observation != null &&
                    widget.cost.observation!.isNotEmpty) ...[
                  Text(
                    "OBSERVAÇÕES",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    widget.cost.observation!,
                    style: AppTextStyles.inputText,
                  ),
                  const SizedBox(height: 16),
                ],

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.greenlightOne.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "VALOR FINAL",
                        style: TextStyle(
                          color: AppColors.greenlightOne,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        Formatters.currency(widget.cost.value),
                        style: AppTextStyles.midText20.copyWith(
                          color: AppColors.greenlightOne,
                          fontSize: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
