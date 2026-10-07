import 'package:flutter/material.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/crop_options.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/common/widgets/area_unit_selector.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/locator.dart';
import 'farm_controller.dart';

class EditFarmPage extends StatefulWidget {
  final FarmModel farm;

  const EditFarmPage({super.key, required this.farm});

  @override
  State<EditFarmPage> createState() => _EditFarmPageState();
}

class _EditFarmPageState extends State<EditFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<FarmController>(); // Agora será utilizado!

  late TextEditingController _nameController;
  late TextEditingController _cadProController;
  late TextEditingController _addressController; // ADICIONADO
  late TextEditingController _totalAreaController;

  final List<Map<String, TextEditingController>> _fieldControllers = [];
  late String _areaUnit = widget.farm.areaUnit;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Preenche os dados principais
    _nameController = TextEditingController(text: widget.farm.name);
    _cadProController = TextEditingController(text: widget.farm.cadPro);
    _addressController = TextEditingController(
      text: widget.farm.address,
    ); // ADICIONADO
    _totalAreaController = TextEditingController(
      text: widget.farm.totalArea,
    ); // CORRIGIDO: Já é String

    // Preenche os talhões existentes
    if (widget.farm.plantedFields.isNotEmpty) {
      for (var field in widget.farm.plantedFields) {
        _fieldControllers.add({
          'name': TextEditingController(text: field['name']),
          'area': TextEditingController(text: field['area'].toString()),
          'crop': TextEditingController(text: field['crop']),
        });
      }
    } else {
      _addField(); // Se não tiver nenhum, adiciona um em branco
    }
  }

  void _addField() {
    setState(() {
      _fieldControllers.add({
        'name': TextEditingController(
          text: "Talhão ${_fieldControllers.length + 1}",
        ),
        'area': TextEditingController(),
        'crop': TextEditingController(),
      });
    });
  }

  void _removeField(int index) {
    setState(() {
      _fieldControllers[index]['name']?.dispose();
      _fieldControllers[index]['area']?.dispose();
      _fieldControllers[index]['crop']?.dispose();
      _fieldControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cadProController.dispose();
    _addressController.dispose(); // ADICIONADO
    _totalAreaController.dispose();
    for (var controllers in _fieldControllers) {
      controllers['name']?.dispose();
      controllers['area']?.dispose();
      controllers['crop']?.dispose();
    }
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      List<Map<String, dynamic>> updatedFields = _fieldControllers.map((c) {
        return {
          'name': c['name']!.text.trim(),
          'area': double.tryParse(c['area']!.text.replaceAll(',', '.')) ?? 0.0,
          'crop': c['crop']!.text.trim(),
        };
      }).toList();

      final updatedFarm = FarmModel(
        id: widget.farm.id,
        name: _nameController.text.trim(),
        cadPro: _cadProController.text.trim(),
        address: _addressController.text
            .trim(), // CORREÇÃO 1: Endereço adicionado
        totalArea: _totalAreaController.text
            .trim(), // CORREÇÃO 2: Mantido como String
        plantedFields: updatedFields,
        // Sem o dono, a fazenda some da lista do produtor após salvar
        ownerId: widget.farm.ownerId,
        areaUnit: _areaUnit,
      );

      // CORREÇÃO 3: Descomentado para salvar no Firebase usando o controller
      await _controller.updateFarm(updatedFarm);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // Fecha a tela de edição
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fazenda atualizada com sucesso!'),
            backgroundColor: AppColors.greenlightOne,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Editar Fazenda",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CustomCircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Dados Principais",
                      style: AppTextStyles.midText20.copyWith(
                        color: AppColors.greenlightOne,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "Nome da Fazenda",
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _cadProController,
                      labelText: "CAD/PRO",
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    // ADICIONADO: Campo para Endereço
                    CustomTextFormField(
                      controller: _addressController,
                      labelText: "Endereço da Propriedade",
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 16),
                    AreaUnitSelector(
                      value: _areaUnit,
                      onChanged: (unit) => setState(() => _areaUnit = unit),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    const SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _totalAreaController,
                      labelText:
                          "Área Total (${AreaUnits.shortLabel(_areaUnit)})",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Áreas de Plantio (Talhões)",
                          style: AppTextStyles.midText20.copyWith(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.greenlightOne,
                            size: 32,
                          ),
                          onPressed: _addField,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(_fieldControllers.length, (index) {
                      final controllers = _fieldControllers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: controllers['name']!,
                                      labelText: "Identificação (Ex: Talhão 1)",
                                      validator: (v) =>
                                          v!.isEmpty ? "Obrigatório" : null,
                                    ),
                                  ),
                                  if (_fieldControllers.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeField(index),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextFormField(
                                      controller: controllers['area']!,
                                      labelText:
                                          "Área Plantada (${AreaUnits.shortLabel(_areaUnit)})",
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (v) =>
                                          v!.isEmpty ? "Obrigatório" : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue:
                                          controllers['crop']!.text.isEmpty
                                          ? null
                                          : controllers['crop']!.text,
                                      decoration: const InputDecoration(
                                        labelText: "Cultura",
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.greenlightOne,
                                          ),
                                        ),
                                      ),
                                      items:
                                          CropOptions.withCurrent(
                                                controllers['crop']!.text,
                                              )
                                              .map(
                                                (crop) => DropdownMenuItem(
                                                  value: crop,
                                                  child: Text(crop),
                                                ),
                                              )
                                              .toList(),
                                      onChanged: (v) {
                                        if (v != null) {
                                          controllers['crop']!.text = v;
                                        }
                                      },
                                      validator: (v) => v == null || v.isEmpty
                                          ? "Obrigatório"
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Atualizar Dados",
                      onPressed: _handleUpdate,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
