import 'dart:developer';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/auth_scaffold.dart';
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

  bool _keepConnected = true;

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
      Navigator.pop(context);
      // Colaborador e produtor têm telas iniciais diferentes
      Navigator.pushNamedAndRemoveUntil(
        context,
        state.isCollaborator ? NamedRoute.collaboratorHome : NamedRoute.home,
        (route) => false,
      );
    } else if (state is SignInStateError) {
      Navigator.pop(context);
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
        keepConnected: _keepConnected,
      );
    } else {
      log("Erro de validação ao logar");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      scrollKey: Keys.signInListView,
      title: 'Bem-vindo de volta',
      subtitle:
          'Acesse sua conta e acompanhe a safra, a lavoura e o caixa da fazenda.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFormField(
                key: Keys.signInEmailField,
                controller: _emailController,
                labelText: "E-mail",
                hintText: "email@email.com",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validator.validateEmail,
                // Permite que o Tab ou o botão Próximo mude o foco
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              PasswordFormField(
                key: Keys.signInPasswordField,
                controller: _passwordController,
                labelText: "Senha",
                hintText: "Sua senha",
                validator: Validator.validatePassword,
                // Como é o último campo, ele confirma a ação
                textInputAction: TextInputAction.done,
                onEditingComplete: _onSignInButtonPressed,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Checkbox(
                value: _keepConnected,
                onChanged: (value) =>
                    setState(() => _keepConnected = value ?? true),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _keepConnected = !_keepConnected),
                  child: Text(
                    "Manter conectado",
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              TextButton(
                key: Keys.forgotPasswordButton,
                // pushNamed (e não popAndPushNamed) para o "voltar" retornar ao login
                onPressed: () =>
                    Navigator.pushNamed(context, NamedRoute.forgotPassword),
                child: const Text('Esqueceu a senha?'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: PrimaryButton(
            key: Keys.signInButton,
            text: 'Entrar',
            icon: Icons.login_rounded,
            onPressed: _onSignInButtonPressed,
          ),
        ),
        AuthSwitchLink(
          key: Keys.signInDontHaveAccountButton,
          question: 'Não tem uma conta?',
          action: 'Cadastre-se',
          onPressed: () => Navigator.popAndPushNamed(context, '/sign_up'),
        ),
      ],
    );
  }
}
