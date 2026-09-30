import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/field_operation_model.dart';
import 'package:agro_comercial/common/models/operation_model.dart';
import 'package:flutter/material.dart';

// Cards usados no histórico de atividades (Home do produtor e do colaborador)

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
      iconColor: Colors.orange,
      icon: Icons.agriculture,
      label: 'Operação de Máquina',
      title: operation.machineName ?? 'Máquina Indefinida',
      subtitle:
          'Operou por ${operation.machineHours ?? 0} hrs - ${operation.title}',
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
    final isVistoria = fieldOperation.type == 'Vistoria';

    return _ActivityCard(
      onTap: onTap,
      iconColor: isVistoria ? Colors.blueAccent : Colors.teal,
      icon: isVistoria ? Icons.search : Icons.water_drop,
      label: fieldOperation.type,
      title: 'Talhão: ${fieldOperation.plotName}',
      subtitle: isVistoria
          ? (fieldOperation.condition ?? 'Vistoria concluída')
          : 'Aplicou ${fieldOperation.productName ?? 'Produto'} com ${fieldOperation.machineName ?? 'Máquina'}',
      registeredBy: registeredBy,
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;
  final String? registeredBy;

  const _ActivityCard({
    required this.onTap,
    required this.iconColor,
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
    this.registeredBy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.lightkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppTextStyles.midText20.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.grey,
                        fontSize: 13,
                      ),
                    ),
                    if (registeredBy != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: AppColors.lightkGrey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Registrado por: $registeredBy',
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.smallText.copyWith(
                                color: AppColors.lightkGrey,
                                fontSize: 12,
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
    );
  }
}
