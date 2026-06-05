import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'edit_machine_controller.dart';

class EditMachinePage extends StatefulWidget {
  final MachineModel machine; // Recebe a máquina clicada

  const EditMachinePage({super.key, required this.machine});

  @override
  State<EditMachinePage> createState() => _EditMachinePageState();
}

class _EditMachinePageState extends State<EditMachinePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _powerController;
  late TextEditingController _hoursController;

  // 1. CRIANDO OS OLHEIROS (FOCUS NODES)
  final _powerFocus = FocusNode();
  final _hoursFocus = FocusNode();

  final _controller = locator.get<EditMachineController>();

  @override
  void initState() {
    super.initState();
    // Preenche os campos com os dados atuais da máquina
    _nameController = TextEditingController(text: widget.machine.name);
    _brandController = TextEditingController(text: widget.machine.brand);
    _modelController = TextEditingController(text: widget.machine.model);
    _powerController = TextEditingController(text: widget.machine.power);
    _hoursController = TextEditingController(
      text: widget.machine.workingHours.toString(),
    );

    _controller.addListener(_handleStateChange);

    // INTELIGÊNCIA DA POTÊNCIA: Esconde o "cv" e seleciona o texto
    _powerFocus.addListener(() {
      setState(() {}); // Atualiza a tela para esconder/mostrar o "cv"
      if (_powerFocus.hasFocus) {
        Future.microtask(() {
          _powerController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _powerController.text.length,
          );
        });
      }
    });

    // INTELIGÊNCIA DAS HORAS: Seleciona o texto automaticamente
    _hoursFocus.addListener(() {
      if (_hoursFocus.hasFocus) {
        Future.microtask(() {
          _hoursController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _hoursController.text.length,
          );
        });
      }
    });
  }

  void _handleStateChange() {
    final state = _controller.state;
    if (state is EditMachineLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is EditMachineSuccessState) {
      Navigator.pop(context); // Fecha o loading
      Navigator.pop(context); // Volta pra tela do armazém
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Máquina atualizada com sucesso!"),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    } else if (state is EditMachineErrorState) {
      Navigator.pop(context); // Fecha o loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    // 2. DESCARTANDO OS FOCUS NODES
    _powerFocus.dispose();
    _hoursFocus.dispose();

    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _powerController.dispose();
    _hoursController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Excluir Máquina",
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
        content: const Text(
          "Tem certeza que deseja excluir esta máquina? Esta ação não pode ser desfeita.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha a caixinha
              _controller.deleteMachineData(
                widget.machine.id!,
              ); // Exclui do banco
            },
            child: const Text(
              "Sim, excluir",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Detalhes da Máquina",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Área da Foto
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
                                "Alterar foto estará disponível em breve!",
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

              CustomTextFormField(
                controller: _nameController,
                labelText: "NOME DA MÁQUINA",
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              CustomTextFormField(
                controller: _brandController,
                labelText: "MARCA",
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),
              CustomTextFormField(
                controller: _modelController,
                labelText: "MODELO",
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
              ),

              // 3. CAMPO DE POTÊNCIA VINCULADO AO FOCUS NODE
              CustomTextFormField(
                controller: _powerController,
                focusNode: _powerFocus, // Vinculando o FocusNode
                labelText: "POTÊNCIA",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
                // A mágica que esconde o CV:
                suffixIcon:
                    !_powerFocus.hasFocus && _powerController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14.0, right: 16.0),
                        child: Text(
                          "cv",
                          style: AppTextStyles.inputText.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      )
                    : null,
              ),

              // 4. CAMPO DE HORAS VINCULADO AO FOCUS NODE
              CustomTextFormField(
                controller: _hoursController,
                focusNode: _hoursFocus, // Vinculando o FocusNode
                labelText: "HORAS TRABALHADAS",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Salvar Alterações',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    // Monta a máquina atualizada mantendo o ID original
                    final updatedMachine = MachineModel(
                      id: widget.machine.id,
                      name: _nameController.text.trim(),
                      brand: _brandController.text.trim(),
                      model: _modelController.text.trim(),
                      power: _powerController.text.trim(),
                      workingHours:
                          int.tryParse(_hoursController.text.trim()) ?? 0,
                      warehouseId: widget.machine.warehouseId,
                      farmId: widget.machine.farmId,
                      imageUrl: widget.machine.imageUrl,
                    );

                    _controller.updateMachineData(updatedMachine);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
