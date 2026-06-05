import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
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
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();

  final _farmController = locator.get<FarmRegistrationController>();

  int _numberOfPlots = 1;
  List<String?> _plotCrops = [null];

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
      Navigator.pop(context); // Fecha o loading
      Navigator.pushReplacementNamed(context, '/home'); // Vai pra Home!
    } else if (state is FarmRegistrationErrorState) {
      Navigator.pop(context); // Fecha o loading
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: "Tentar novamente",
      );
    }
  }

  void _onPlotsChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _numberOfPlots = newValue;
        List<String?> newCrops = List.filled(_numberOfPlots, null);
        for (int i = 0; i < _numberOfPlots && i < _plotCrops.length; i++) {
          newCrops[i] = _plotCrops[i];
        }
        _plotCrops = newCrops;
      });
    }
  }

  void _onSaveButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_plotCrops.contains(null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Por favor, selecione a cultura de todos os talhões.",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Chama o controller em vez de navegar direto
      _farmController.saveFarm(
        name: _nameController.text,
        address: _addressController.text,
        area: _areaController.text,
        numberOfPlots: _numberOfPlots,
        plotCrops: _plotCrops,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _farmController.dispose();
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
                CustomTextFormField(
                  controller: _addressController,
                  labelText: "Endereço da Propriedade",
                  hintText: "Ex: Estrada Rural, Mandaguari - PR",
                  validator: (value) => value == null || value.isEmpty
                      ? "O endereço não pode ser vazio"
                      : null,
                ),
                CustomTextFormField(
                  controller: _areaController,
                  labelText: "Área Total (Alqueires ou Hectares)",
                  hintText: "Ex: 50",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validator.validateNumber,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  child: DropdownButtonFormField<int>(
                    initialValue: _numberOfPlots,
                    decoration: InputDecoration(
                      labelText: "Quantidade de Talhões",
                      labelStyle: AppTextStyles.inputLabelText.copyWith(
                        color: AppColors.lightkGrey,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.greenlightOne),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.greenlightOne),
                      ),
                    ),
                    items: List.generate(10, (index) => index + 1)
                        .map(
                          (number) => DropdownMenuItem(
                            value: number,
                            child: Text('$number Talhão(ões)'),
                          ),
                        )
                        .toList(),
                    onChanged: _onPlotsChanged,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Divider(color: AppColors.greenlightOne),
                ),
                ...List.generate(_numberOfPlots, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 8.0,
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _plotCrops[index],
                      decoration: InputDecoration(
                        labelText: "Cultura do Talhão ${index + 1}",
                        labelStyle: AppTextStyles.inputLabelText.copyWith(
                          color: AppColors.lightkGrey,
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
                      ),
                      hint: const Text("Selecione o que você planta"),
                      items: _cropOptions.map((crop) {
                        return DropdownMenuItem(value: crop, child: Text(crop));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _plotCrops[index] = value;
                        });
                      },
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
