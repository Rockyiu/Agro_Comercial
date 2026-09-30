import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:flutter/material.dart';

// Lista as fazendas do produtor e devolve a escolhida (ou null se cancelar)
Future<FarmModel?> showFarmSelectorDialog(
  BuildContext context,
  List<FarmModel> farms,
) {
  return showDialog<FarmModel>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text("Selecione a Fazenda"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              return ListTile(
                leading: const Icon(
                  Icons.home_work,
                  color: AppColors.greenlightOne,
                ),
                title: Text(farm.name),
                subtitle: Text(
                  'Área: ${farm.totalArea} | Talhões: ${farm.plantedFields.length}',
                ),
                onTap: () => Navigator.pop(dialogContext, farm),
              );
            },
          ),
        ),
      );
    },
  );
}
