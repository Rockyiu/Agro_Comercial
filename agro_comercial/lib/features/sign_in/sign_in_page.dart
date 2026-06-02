import 'dart:developer';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/multi_text_button.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

import '../../locator.dart';
import '../../services/sync_service/sync_service.dart';
import 'sign_in_controller.dart';
import 'sign_in_state.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> with CustomModalSheetMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _signInController = locator.get<SignInController>();
  final _syncController = locator.get<SyncController>();

  @override
  void initState() {
    super.initState();
    _signInController.addListener(_handleSignInStateChange);
    _syncController.addListener(_handleSyncStateChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signInController.dispose();
    _syncController.dispose();
    super.dispose();
  }

  void _handleSignInStateChange() {
    switch (_signInController.state.runtimeType) {
      case SignInStateLoading:
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const CustomCircularProgressIndicator(),
        );
        break;
      case SignInStateSuccess:
        _syncController.syncFromServer();
        break;
      case SignInStateError:
        Navigator.pop(context); // Remove o loading
        showCustomModalBottomSheet(
          context: context,
          content: (_signInController.state as SignInStateError).message,
          buttonText: "Tentar novamente",
        );
        break;
    }
  }

  void _handleSyncStateChange() {
    switch (_syncController.state.runtimeType) {
      case DownloadedDataFromServer:
        _syncController.syncToServer();
        break;
      case UploadedDataToServer:
        Navigator.pushNamedAndRemoveUntil(
          context,
          NamedRoute.home,
          (route) => false,
        );
        break;
      case SyncStateError:
      case UploadDataToServerError:
      case DownloadDataFromServerError:
        Navigator.pop(context); // Remove o loading
        showCustomModalBottomSheet(
          context: context,
          content: (_syncController.state as SyncStateError).message,
          buttonText: "Tentar novamente",
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            NamedRoute.signIn,
            (route) => false,
          ),
        );
        break;
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
          const SizedBox(height: 48), // Espaço para não colar no topo
          Text(
            'Bem-vindo de volta!',
            textAlign: TextAlign.center,
            style: AppTextStyles.midText36.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
          // Se tiver a imagem descomente abaixo, mas recomendo ajustar a altura
          // Image.asset('assets/images/sign_in_image.png', height: 200),
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
              onPressed: () =>
                  Navigator.popAndPushNamed(context, NamedRoute.forgotPassword),
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
            onPressed: () =>
                Navigator.popAndPushNamed(context, NamedRoute.signUp),
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
