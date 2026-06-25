import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'employee_controller.dart';
import 'employee_state.dart';

class RegisterEmployeePage extends StatefulWidget {
  const RegisterEmployeePage({super.key});

  @override
  State<RegisterEmployeePage> createState() => _RegisterEmployeePageState();
}

class _RegisterEmployeePageState extends State<RegisterEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();

  final _controller = locator.get<EmployeeController>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Novo Funcionário",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_isProcessing)
            return const Center(child: CustomCircularProgressIndicator());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.greenlightOne.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Ao registrar o CPF aqui, o funcionário será autorizado a criar uma conta e será vinculado automaticamente à sua fazenda.",
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.greenlightOne,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextFormField(
                    controller: _nameController,
                    labelText: "NOME DO FUNCIONÁRIO",
                    validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    controller: _cpfController,
                    labelText: "CPF (Apenas Números)",
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Obrigatório";
                      String numeros = v.replaceAll(RegExp(r'[^0-9]'), '');
                      if (numeros.length != 11)
                        return "O CPF deve conter 11 dígitos";
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: "Autorizar Acesso",
                    onPressed: () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() => _isProcessing = true);
                        await _controller.registerEmployee(
                          _nameController.text.trim(),
                          _cpfController.text.trim(),
                        );
                        if (!context.mounted) return;
                        if (_controller.state is EmployeeErrorState) {
                          setState(() => _isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                (_controller.state as EmployeeErrorState)
                                    .message,
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
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
