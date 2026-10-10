import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';

// Cards usados no histórico de atividades (Home do produtor e do colaborador)

// Ex: "Talhão 3 • Trator T250 • 2,5h"
String _operationDetails(OperationModel op) {
  final plot = op.plotName ?? '';
  final hours = op.machineHours;
  return [
    plot.isEmpty ? 'Fazenda inteira' : plot,
    if (op.usedMachine && op.machineName != null) op.machineName!,
    if (op.usedMachine && hours != null) Formatters.hours(hours),
  ].join(' • ');
}

// Ex: "Aplicou Glifosato com Pulverizador 4630"
String _applicationDetails(FieldOperationModel op) {
  final product = op.productName ?? 'produto';
  final machine = op.machineName;
  return machine == null ? 'Aplicou $product' : 'Aplicou $product com $machine';
}

class OperationActivityCard extends StatelessWidget {
  final OperationModel operation;
  final VoidCallback? onTap;
  final String? registeredBy; // Nome de quem registrou (opcional)

  const OperationActivityCard({
    super.key,
    required this.operation,
    this.onTap,
    this.registeredBy,
  });

  @override
  Widget build(BuildContext context) {
    return _ActivityCard(
      onTap: onTap,
      color: AppColors.earth,
      background: AppColors.earthSoft,
      icon: Icons.agriculture_rounded,
      label: 'Operação',
      title: operation.title,
      subtitle: _operationDetails(operation),
      date: operation.dateTimestamp,
      registeredBy: registeredBy,
    );
  }
}

class FieldOperationActivityCard extends StatelessWidget {
  final FieldOperationModel fieldOperation;
  final VoidCallback? onTap;
  final String? registeredBy; // Nome de quem registrou (opcional)

  const FieldOperationActivityCard({
    super.key,
    required this.fieldOperation,
    this.onTap,
    this.registeredBy,
  });

  @override
  Widget build(BuildContext context) {
    final isInspection = fieldOperation.isInspection;

    return _ActivityCard(
      onTap: onTap,
      color: isInspection ? AppColors.sky : AppColors.water,
      background: isInspection ? AppColors.skySoft : AppColors.waterSoft,
      icon: isInspection
          ? Icons.travel_explore_rounded
          : Icons.water_drop_rounded,
      label: fieldOperation.type,
      title: fieldOperation.plotName,
      subtitle: isInspection
          ? (fieldOperation.condition ?? 'Vistoria concluída')
          : _applicationDetails(fieldOperation),
      date: fieldOperation.dateTimestamp,
      registeredBy: registeredBy,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color;
  final Color background;
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final int date;
  final String? registeredBy;

  const _ActivityCard({
    required this.onTap,
    required this.color,
    required this.background,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.date,
    this.registeredBy,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        enabled: onTap != null,
        child: Material(
          color: AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusChip(
                              label: label,
                              color: color,
                              background: background,
                            ),
                            const Spacer(),
                            Text(
                              Formatters.date(date),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        if (registeredBy != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: AppColors.primarySoft,
                                child: Text(
                                  registeredBy!.isEmpty
                                      ? '?'
                                      : registeredBy![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  registeredBy!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
