import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/widgets/activity_card.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
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
  // Blocos acima da lista (cartão da fazenda, indicadores, atalhos)
  final List<Widget> header;

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
    this.header = const [],
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

    return [
      for (var i = 0; i < combined.length; i++)
        FadeSlideIn(index: i, child: combined[i].card),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final count = operations.length + fieldOperations.length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        // Permite o "puxar para atualizar" mesmo com a lista vazia
        physics: const AlwaysScrollableScrollPhysics(),
        // Espaço no final para o botão (+) não cobrir o último card
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        children: [
          for (final block in header) ...[block, const SizedBox(height: 20)],
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
            child: SectionHeader(
              title: title,
              subtitle: count == 0
                  ? null
                  : '$count ${count == 1 ? 'registro' : 'registros'}',
            ),
          ),
          if (count == 0) emptyState else ..._buildCards(),
        ],
      ),
    );
  }
}
