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
import 'package:agro_comercial/features/sign_in/sign_in_controller.dart';
import 'package:agro_comercial/features/sign_in/sign_in_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/services/mock_auth_service.dart';
import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _controller = locator.get<SignInController>();

  // Caso esta função não exista no seu código ainda, deixei ela criada vazia para não dar erro no botão
  void _onSignInButtonPressed() {
    // Lógica de cadastro vai aqui
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.state is SignInStateLoading) {
        showDialog(
          context: context,
          builder: (context) => const CustomCircularProgressIndicator(),
        );
      }
      if (_controller.state is SignInStateSuccess) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Scaffold(body: Center(child: Text("Nova Tela"))),
          ),
        );
      }
      if (_controller.state is SignInStateError) {
        final error = _controller.state as SignInStateError;
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
      body: ListView(
        children: [
          Text(
            'Bem Vindo de Volta!',
            textAlign: TextAlign.center,
            style: AppTextStyles.midText36.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextFormField(
                  controller: _emailController,
                  labelText: "seu email",
                  hintText: "email@email.com",
                  validator: Validator.validateEmail,
                ),
                PasswordFormField(
                  controller: _passwordController,
                  labelText: "Escolha a sua senha",
                  hintText: "*******",
                  validator: Validator.validatePassword,
                  helperText:
                      "Sua senha deve ter no minimo 8 caracteres, um caracter especial, numero e letra maiscula",
                ),
              ], // <-- Fechamento corrigido dos filhos da Column
            ), // <-- Fechamento da Column
          ), // <-- Fechamento do Form
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 16.0,
              bottom: 4.0,
            ),
            child: PrimaryButton(
              // key: Keys.SignInButton, // Descomente se tiver as chaves configuradas
              text: 'Sign Ip',
              onPressed: _onSignInButtonPressed,
            ),
          ),
          MultiTextButton(
            // key: Keys.SignInAlreadyHaveAccountButton, // Descomente se tiver as chaves configuradas
            // Substitua '/sign_in' por NamedRoute.signIn se tiver configurado suas rotas nomeadas
            onPressed: () => Navigator.popAndPushNamed(context, '/sign_in'),
            children: [
              Text(
                'Ja tem uma conta? ',
                style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
              ),
              Text(
                'Sign In ',
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
            ],
          ),
        ],
      ), // Fechamento do ListView
    ); // Fechamento do Scaffold que estava faltando!
  }
}
