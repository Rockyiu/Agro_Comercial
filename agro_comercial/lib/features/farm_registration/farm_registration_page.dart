import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'farm_registration_controller.dart';
import 'farm_registration_state.dart';

class FarmRegistrationPage extends StatefulWidget {
  const FarmRegistrationPage({super.key});

  @override
  State<FarmRegistrationPage> createState() => _FarmRegistrationPageState();
}

class _FarmRegistrationPageState extends State<FarmRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cadProController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalAreaController = TextEditingController();

  final _farmController = locator.get<FarmRegistrationController>();

  final List<Map<String, TextEditingController>> _fieldControllers = [];

  // A SUA LISTA DE CULTURAS VOLTOU AQUI!
  final List<String> _cropOptions = [
    'Soja',
    'Milho',
    'Trigo',
    'Café',
    'Cana-de-açúcar',
    'Feijão',
    'Cenoura',
    'Tomate',
    'Algodão',
    'Laranja',
    'Pastagem',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _farmController.addListener(_handleStateChange);
    _addField();
  }

  void _handleStateChange() {
    final state = _farmController.state;

    if (state is FarmRegistrationLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is FarmRegistrationSuccessState) {
      Navigator.pop(context);

      locator.get<FarmController>().loadFarms();

      Navigator.pushReplacementNamed(context, '/home');
    } else if (state is FarmRegistrationErrorState) {
      Navigator.pop(context);
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: "Tentar novamente",
      );
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

  void _onSaveButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      List<Map<String, dynamic>> plantedFields = _fieldControllers.map((c) {
        return {
          'name': c['name']!.text.trim(),
          'area': double.tryParse(c['area']!.text.replaceAll(',', '.')) ?? 0.0,
          'crop': c['crop']!.text.trim(),
        };
      }).toList();

      _farmController.saveFarm(
        name: _nameController.text.trim(),
        cadPro: _cadProController.text.trim(),
        address: _addressController.text.trim(),
        totalArea: _totalAreaController.text.trim(),
        plantedFields: plantedFields,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cadProController.dispose();
    _addressController.dispose();
    _totalAreaController.dispose();
    _farmController.removeListener(_handleStateChange);

    for (var controllers in _fieldControllers) {
      controllers['name']?.dispose();
      controllers['area']?.dispose();
      controllers['crop']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Configurar Propriedade",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        backgroundColor: AppColors.iceWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          Text(
            'Quase lá! Vamos configurar a sua fazenda.',
            textAlign: TextAlign.center,
            style: AppTextStyles.midText20.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 32),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Nome da Propriedade",
                  hintText: "Ex: Fazenda Santa Maria",
                  validator: (value) => value == null || value.isEmpty
                      ? "O nome não pode ser vazio"
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _cadProController,
                  labelText: "CAD/PRO (Inscrição Estadual)",
                  hintText: "Apenas números",
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? "O CAD/PRO não pode ser vazio"
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _addressController,
                  labelText: "Endereço da Propriedade",
                  hintText: "Ex: Estrada Rural, Mandaguari - PR",
                  validator: (value) => value == null || value.isEmpty
                      ? "O endereço não pode ser vazio"
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _totalAreaController,
                  labelText: "Área Total (Alqueires ou Hectares)",
                  hintText: "Ex: 50",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validator.validateNumber,
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
                const Divider(color: AppColors.greenlightOne),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: CustomTextFormField(
                                  controller: controllers['area']!,
                                  labelText: "Área Plantada",
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (v) =>
                                      v!.isEmpty ? "Obrigatório" : null,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // O NOVO DROPDOWN ESTÁ AQUI!
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue:
                                      controllers['crop']!.text.isEmpty
                                      ? null
                                      : controllers['crop']!.text,
                                  decoration: InputDecoration(
                                    labelText: "Cultura",
                                    labelStyle: AppTextStyles.inputLabelText
                                        .copyWith(color: AppColors.lightkGrey),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.greenlightOne,
                                      ),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.greenlightOne,
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.greenlightOne,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  hint: const Text(
                                    "Selecione",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  items: _cropOptions.map((String crop) {
                                    return DropdownMenuItem<String>(
                                      value: crop,
                                      child: Text(
                                        crop,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      controllers['crop']!.text =
                                          newValue; // Salva a escolha no controlador invisível
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
              ],
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: PrimaryButton(
              text: 'Salvar e Continuar',
              onPressed: _onSaveButtonPressed,
            ),
          ),
        ],
      ),
    );
  }
}
