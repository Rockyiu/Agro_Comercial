import 'dart:developer';

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

  // Corrigido a falta de ponto e vírgula
  final _signUpController = locator.get<SignUpController>();

  // Variável para armazenar o tipo de usuário selecionado
  String _selectedRole = 'admin';

  void _onSignUpButtonPressed() {
    // Valida todos os campos do Form antes de chamar o Controller
    if (_formKey.currentState?.validate() ?? false) {
      _signUpController.SignUp(
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
    // Corrigida a referência da variável do controller (de _controller para _signUpController)
    _signUpController.addListener(() {
      if (_signUpController.state is SignUpLoadingState) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CustomCircularProgressIndicator(),
        );
      }
      if (_signUpController.state is SignUpSuccessState) {
        Navigator.pop(context); // Remove o loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const Scaffold(body: Center(child: Text("Home Page"))),
          ),
        );
      }
      if (_signUpController.state is SignUpErrorState) {
        final error = _signUpController.state as SignUpErrorState;
        Navigator.pop(context); // Remove o loading
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        children: [
          Text(
            'Insira seus dados!',
            textAlign: TextAlign.center,
            style: AppTextStyles.midText36.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Seu nome",
                  hintText: "Nome Completo",
                  inputFormatters: [UpperCaseTextInputFormatter()],
                  validator: Validator.validateName,
                ),
                CustomTextFormField(
                  controller: _cpfController,
                  labelText: "Seu CPF",
                  hintText: "Apenas números",
                  keyboardType: TextInputType.number,
                  validator: Validator.validateCPF,
                ),
                CustomTextFormField(
                  controller: _emailController,
                  labelText: "Seu e-mail",
                  hintText: "email@email.com",
                  keyboardType: TextInputType.emailAddress,
                  validator: Validator.validateEmail,
                ),

                // Dropdown para seleção de Perfil
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: "Selecione o seu Perfil",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
                ),

                PasswordFormField(
                  controller: _passwordController,
                  labelText: "Escolha a sua senha",
                  hintText: "*******",
                  validator: Validator.validatePassword,
                  helperText:
                      "Sua senha deve ter no minimo 8 caracteres, um caracter especial, numero e letra maiscula",
                ),
                PasswordFormField(
                  labelText: "Confirme sua senha",
                  hintText: "*******",
                  validator: (value) => Validator.validateConfirmPassword(
                    _passwordController.text,
                    value,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 24.0,
              bottom: 4.0,
            ),
            child: PrimaryButton(
              text: 'Sign Up',
              onPressed: _onSignUpButtonPressed,
            ),
          ),
          MultiTextButton(
            onPressed: () => Navigator.popAndPushNamed(context, '/sign_in'),
            children: [
              Text(
                'Já tem uma conta? ',
                style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
              ),
              Text(
                'Sign In',
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
