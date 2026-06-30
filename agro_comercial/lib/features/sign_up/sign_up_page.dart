import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/utils/uppercase_text_formatter.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/multi_text_button.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/farm_registration/farm_registration_page.dart';
import 'package:agro_comercial/features/home/collaborator_home_page.dart';
import 'package:agro_comercial/features/sign_up/sign_up_controller.dart';
import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:agro_comercial/locator.dart';

import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();

  final _signUpController = locator.get<SignUpController>();

  String _selectedRole = 'admin';

  void _onSignUpButtonPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      _signUpController.signUp(
        name: _nameController.text,
        email: _emailController.text,
        cpf: _cpfController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _signUpController.addListener(() {
      if (_signUpController.state is SignUpLoadingState) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CustomCircularProgressIndicator(),
        );
      }
      if (_signUpController.state is SignUpSuccessState) {
        Navigator.pop(context);

        if (_selectedRole == 'admin') {
          // Admin vai para o registo da fazenda
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmRegistrationPage(),
            ),
          );
        } else {
          // AQUI ESTÁ A CORREÇÃO: Colaborador vai para a tela dele!
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CollaboratorHomePage(),
            ),
          );
        }
      }
      if (_signUpController.state is SignUpErrorState) {
        final error = _signUpController.state as SignUpErrorState;
        Navigator.pop(context);
        customModalBottomSheet(
          context,
          content: error.message,
          buttonText: "Tentar novamente",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      // SafeArea garante que o app não invada a área da câmera/bateria
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Insira seus dados!',
                textAlign: TextAlign.center,
                style: AppTextStyles.midText36.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "SEU NOME",
                      hintText: "Nome Completo",
                      inputFormatters: [UpperCaseTextInputFormatter()],
                      validator: Validator
                          .validateName, // <-- Voltou a usar o Validator global
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _cpfController,
                      labelText: "SEU CPF",
                      hintText: "Apenas números",
                      keyboardType: TextInputType.number,
                      validator: Validator.validateCPF,
                    ),
                    const SizedBox(height: 16),
                    CustomTextFormField(
                      controller: _emailController,
                      labelText: "SEU E-MAIL",
                      hintText: "email@email.com",
                      keyboardType: TextInputType.emailAddress,
                      validator: Validator.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: InputDecoration(
                        labelText: "SELECIONE O SEU PERFIL",
                        labelStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: AppColors.greenlightOne,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: AppColors.greenlightOne,
                            width: 2,
                          ),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Proprietário (Admin)'),
                        ),
                        DropdownMenuItem(
                          value: 'colaborador',
                          child: Text('Colaborador'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedRole = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PasswordFormField(
                      controller: _passwordController,
                      labelText: "ESCOLHA A SUA SENHA",
                      hintText: "*******",
                      validator: Validator.validatePassword,
                      helperText:
                          "No mínimo 8 caracteres, um caracter especial, número e letra maiúscula",
                    ),
                    const SizedBox(height: 16),
                    PasswordFormField(
                      labelText: "CONFIRME SUA SENHA",
                      hintText: "*******",
                      validator: (value) => Validator.validateConfirmPassword(
                        _passwordController.text,
                        value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Cadastrar',
                onPressed: _onSignUpButtonPressed,
              ),
              const SizedBox(height: 16),
              MultiTextButton(
                onPressed: () => Navigator.popAndPushNamed(context, '/sign_in'),
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  Text(
                    'Entrar',
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.greenlightOne,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
