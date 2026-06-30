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
import 'package:shared_preferences/shared_preferences.dart';

// --- ADICIONADOS PARA A VERIFICAÇÃO ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/features/home/collaborator_home_page.dart';

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
      Navigator.pop(context); // Remove o loading

      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('keepConnected', _keepConnected);
      });

      // AQUI CHAMAMOS A VERIFICAÇÃO EM VEZ DE IR DIRETO PRA HOME
      _redirectBasedOnRole();
    } else if (state is SignInStateError) {
      Navigator.pop(context); // Remove o loading
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: "Tentar novamente",
      );
    }
  }

  // Função que vai no banco ver se é Admin ou Colaborador
  Future<void> _redirectBasedOnRole() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CustomCircularProgressIndicator(),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      bool isCollaborator = false;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final data = doc.data();

        if (data != null) {
          if (data['role'] == 'colaborador' || data['tipo'] == 'colaborador') {
            isCollaborator = true;
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context);

      // Redirecionamento Dinâmico
      if (isCollaborator) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CollaboratorHomePage()),
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
                Row(
                  children: [
                    Checkbox(
                      value: _keepConnected,
                      onChanged: (value) {
                        setState(() {
                          _keepConnected = value ?? true;
                        });
                      },
                      activeColor: AppColors.greenlightOne,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _keepConnected = !_keepConnected;
                        });
                      },
                      child: Text(
                        "Manter-me conectado",
                        style: AppTextStyles.smallText.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: Keys.forgotPasswordButton,
              onPressed: () =>
                  Navigator.popAndPushNamed(context, '/forgot_password'),
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
            onPressed: () => Navigator.popAndPushNamed(context, '/sign_up'),
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
