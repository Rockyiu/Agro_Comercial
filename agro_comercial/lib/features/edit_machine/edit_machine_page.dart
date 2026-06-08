import 'dart:io';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/machine_model.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'edit_machine_controller.dart';

class EditMachinePage extends StatefulWidget {
  final MachineModel machine;

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

  final _powerFocus = FocusNode();
  final _hoursFocus = FocusNode();
  File? _newSelectedImage;

  final _controller = locator.get<EditMachineController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.machine.name);
    _brandController = TextEditingController(text: widget.machine.brand);
    _modelController = TextEditingController(text: widget.machine.model);
    _powerController = TextEditingController(text: widget.machine.power);
    _hoursController = TextEditingController(
      text: widget.machine.workingHours.toString(),
    );

    _controller.addListener(_handleStateChange);

    _powerFocus.addListener(() {
      setState(() {});
      if (_powerFocus.hasFocus) {
        Future.microtask(() {
          _powerController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _powerController.text.length,
          );
        });
      }
    });

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
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Máquina atualizada com sucesso!"),
          backgroundColor: AppColors.greenlightOne,
        ),
      );
    } else if (state is EditMachineErrorState) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Nova Foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null)
                  setState(() => _newSelectedImage = File(photo.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher Nova da Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null)
                  setState(() => _newSelectedImage = File(image.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
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
              Navigator.pop(context);
              _controller.deleteMachineData(widget.machine.id!);
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
                      child: _newSelectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.file(
                                _newSelectedImage!,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : (widget.machine.imageUrl != null &&
                                widget.machine.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                widget.machine.imageUrl!,
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
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
                        onPressed: _pickImage,
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

              CustomTextFormField(
                controller: _powerController,
                focusNode: _powerFocus,
                labelText: "POTÊNCIA",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
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

              CustomTextFormField(
                controller: _hoursController,
                focusNode: _hoursFocus,
                labelText: "HORAS TRABALHADAS",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Salvar Alterações',
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
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

                    // CORRIGIDO: Passando a nova imagem selecionada como segundo argumento
                    _controller.updateMachineData(
                      updatedMachine,
                      _newSelectedImage,
                    );
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
