import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'register_machine_controller.dart';
import 'register_machine_state.dart';

class RegisterMachinePage extends StatefulWidget {
  const RegisterMachinePage({super.key});

  @override
  State<RegisterMachinePage> createState() => _RegisterMachinePageState();
}

class _RegisterMachinePageState extends State<RegisterMachinePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _powerController = TextEditingController();
  final _hoursController = TextEditingController();

  WarehouseModel? _selectedWarehouse;
  bool _isMotorized = true; // NOVA VARIÁVEL DE ESTADO
  final _controller = locator.get<RegisterMachineController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
    _controller.loadWarehouses();
  }

  void _handleStateChange() {
    final state = _controller.state;
    if (state is RegisterMachineLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is RegisterMachineSuccessState) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Máquina salva com sucesso!"),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    } else if (state is RegisterMachineErrorState) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Cadastrar Máquina",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoadingWarehouses) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          if (_controller.warehouses.isEmpty) {
            return const Center(
              child: Text("Crie um armazém antes de cadastrar uma máquina!"),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.greenlightOne,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.agriculture,
                            size: 60,
                            color: AppColors.lightkGrey,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: AppColors.greenlightOne,
                          radius: 20,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Adicionar foto estará disponível em breve!",
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: DropdownButtonFormField<WarehouseModel>(
                      decoration: InputDecoration(
                        labelText: "SELECIONE O ARMAZÉM",
                        labelStyle: AppTextStyles.inputLabelText.copyWith(
                          color: AppColors.lightkGrey,
                        ),
                        focusedBorder: const OutlineInputBorder(
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
                      initialValue: _selectedWarehouse,
                      items: _controller.warehouses.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w.name));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedWarehouse = value),
                      validator: (value) =>
                          value == null ? "Selecione um armazém" : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomTextFormField(
                    controller: _nameController,
                    labelText: "NOME DA MÁQUINA",
                    hintText: "Ex: Trator Principal",
                    validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  CustomTextFormField(
                    controller: _brandController,
                    labelText: "MARCA",
                    hintText: "Ex: John Deere, Massey Ferguson",
                    validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  CustomTextFormField(
                    controller: _modelController,
                    labelText: "MODELO",
                    hintText: "Ex: 5075E",
                    validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  CustomTextFormField(
                    controller: _powerController,
                    labelText: "POTÊNCIA",
                    hintText: "Ex: 75 CV",
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                  ),
                  const SizedBox(height: 16),

                  // ADICIONADO: CHAVE SELETORA DE MOTOR
                  SwitchListTile(
                    title: Text(
                      "Possui motor / Horímetro?",
                      style: AppTextStyles.inputText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Desmarque para implementos manuais, aplicadores costais, etc.",
                      style: AppTextStyles.smallText,
                    ),
                    activeColor: AppColors.greenlightOne,
                    value: _isMotorized,
                    onChanged: (val) => setState(() => _isMotorized = val),
                  ),
                  const SizedBox(height: 16),

                  // ADICIONADO: SÓ MOSTRA SE FOR MOTORIZADO
                  if (_isMotorized)
                    CustomTextFormField(
                      controller: _hoursController,
                      labelText: "HORAS TRABALHADAS (Opcional)",
                      hintText: "Ex: 50 (Fica 0 se vazio)",
                      keyboardType: TextInputType.number,
                    ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: 'Salvar Máquina',
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _controller.saveMachine(
                          name: _nameController.text,
                          brand: _brandController.text,
                          model: _modelController.text,
                          power: _powerController.text,
                          // Se não for motorized, envia vazio para salvar como 0
                          workingHoursStr: _isMotorized
                              ? _hoursController.text
                              : "",
                          warehouseId: _selectedWarehouse!.id!,
                          isMotorized: _isMotorized,
                          imageFile: null,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
