import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/cost_model.dart';

import 'register_cost_page.dart';

class CostDetailsPage extends StatefulWidget {
  final CostModel cost;

  const CostDetailsPage({super.key, required this.cost});

  @override
  State<CostDetailsPage> createState() => _CostDetailsPageState();
}

class _CostDetailsPageState extends State<CostDetailsPage> {
  bool _isCollaborator = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _isCollaborator = doc.data()?['role'] == 'colaborador';
        });
      }
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  String _formatDate(int timestamp) {
    return DateFormat(
      'dd/MM/yyyy',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  @override
  Widget build(BuildContext context) {
    // Regra de segurança: Esconde o botão de editar se for colaborador E o custo for mão de obra
    bool isLaborCost = widget.cost.category.toLowerCase().contains('obra');
    bool showEditButton = !(_isCollaborator && isLaborCost);

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
                if (result == true && mounted) {
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
                  _formatDate(widget.cost.dateTimestamp),
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
                        _formatCurrency(widget.cost.value),
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
