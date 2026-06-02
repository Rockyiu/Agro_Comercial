import 'dart:developer';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/multi_text_button.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

import '../../locator.dart';
import 'sign_in_controller.dart';
import 'sign_in_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signInController = locator.get<SignInController>();

  @override
  void initState() {
    super.initState();
    _signInController.addListener(_handleSignInStateChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signInController.dispose();
    super.dispose();
  }

  void _handleSignInStateChange() {
    final state = _signInController.state;

    if (state is SignInStateLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is SignInStateSuccess) {
      Navigator.pop(context); // Remove o loading

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home', // Rota em string para evitar erro de classe não definida
        (route) => false,
      );
    } else if (state is SignInStateError) {
      Navigator.pop(context); // Remove o loading
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: "Tentar novamente",
      );
    }
  }

  void _onSignInButtonPressed() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid) {
      _signInController.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } else {
      log("Erro de validação ao logar");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        key: Keys.signInListView,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        children: [
          const SizedBox(height: 48),
          Text(
            'Bem-vindo de volta!',
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
                  key: Keys.signInEmailField,
                  controller: _emailController,
                  labelText: "Seu e-mail",
                  hintText: "email@email.com",
                  keyboardType: TextInputType.emailAddress,
                  validator: Validator.validateEmail,
                ),
                PasswordFormField(
                  key: Keys.signInPasswordField,
                  controller: _passwordController,
                  labelText: "Sua senha",
                  hintText: "*********",
                  validator: Validator.validatePassword,
                  onEditingComplete: _onSignInButtonPressed,
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: Keys.forgotPasswordButton,
              onPressed: () => Navigator.popAndPushNamed(
                context,
                '/forgot_password',
              ), // Rota corrigida
              child: const Text('Esqueceu a senha?'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              right: 32.0,
              top: 16.0,
              bottom: 4.0,
            ),
            child: PrimaryButton(
              key: Keys.signInButton,
              text: 'Entrar',
              onPressed: _onSignInButtonPressed,
            ),
          ),
          MultiTextButton(
            key: Keys.signInDontHaveAccountButton,
            onPressed: () => Navigator.popAndPushNamed(
              context,
              '/sign_up',
            ), // Rota corrigida
            children: [
              Text(
                'Não tem uma conta? ',
                style: AppTextStyles.smallText.copyWith(color: AppColors.grey),
              ),
              Text(
                'Cadastre-se',
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
