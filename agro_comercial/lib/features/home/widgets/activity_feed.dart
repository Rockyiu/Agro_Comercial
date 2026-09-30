import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/widgets/activity_card.dart';
import 'package:flutter/material.dart';

// Lista de atividades (operações + vistorias/aplicações), da mais recente
// para a mais antiga, com "puxar para atualizar". Usada nas duas Homes.
class ActivityFeed extends StatelessWidget {
  final String title;
  final List<OperationModel> operations;
  final List<FieldOperationModel> fieldOperations;
  final Widget emptyState;
  final Future<void> Function() onRefresh;
  final ValueChanged<OperationModel> onOperationTap;
  final ValueChanged<FieldOperationModel> onFieldOperationTap;
  // Nome de quem registrou cada atividade; se for nulo, a linha não aparece
  final String Function(String? createdBy)? authorName;

  const ActivityFeed({
    super.key,
    required this.title,
    required this.operations,
    required this.fieldOperations,
    required this.emptyState,
    required this.onRefresh,
    required this.onOperationTap,
    required this.onFieldOperationTap,
    this.authorName,
  });

  List<Widget> _buildCards() {
    final combined = <({int timestamp, Widget card})>[
      for (final op in operations)
        (
          timestamp: op.dateTimestamp,
          card: OperationActivityCard(
            operation: op,
            registeredBy: authorName?.call(op.createdBy),
            onTap: () => onOperationTap(op),
          ),
        ),
      for (final fOp in fieldOperations)
        (
          timestamp: fOp.dateTimestamp,
          card: FieldOperationActivityCard(
            fieldOperation: fOp,
            registeredBy: authorName?.call(fOp.createdBy),
            onTap: () => onFieldOperationTap(fOp),
          ),
        ),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return combined.map((e) => e.card).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = operations.isEmpty && fieldOperations.isEmpty;

    return RefreshIndicator(
      color: AppColors.greenlightOne,
      onRefresh: onRefresh,
      child: ListView(
        // Permite o "puxar para atualizar" mesmo com a lista vazia
        physics: const AlwaysScrollableScrollPhysics(),
        // Espaço no final para o botão (+) não cobrir o último card
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: Text(
              title,
              style: AppTextStyles.midText20.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
          ),
          if (isEmpty) emptyState else ..._buildCards(),
        ],
      ),
    );
  }
}
