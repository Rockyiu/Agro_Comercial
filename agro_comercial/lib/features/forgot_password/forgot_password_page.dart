import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:flutter/material.dart';

import '../../locator.dart';
import 'forgot_password_controller.dart';
import 'forgot_password_state.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _controller = locator.get<ForgotPasswordController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleStateChange() {
    final state = _controller.state;

    if (state is ForgotPasswordLoadingState) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is ForgotPasswordSuccessState) {
      Navigator.pop(context);
      // Por segurança o Firebase não informa se o e-mail existe,
      // por isso a mensagem é sempre a mesma.
      customModalBottomSheet(
        context,
        content:
            'Se houver uma conta com ${state.email}, você receberá um link para criar uma nova senha. Confira também a caixa de spam.',
        buttonText: 'Voltar para o login',
        onPressed: () {
          Navigator.pop(context); // Fecha o BottomSheet
          _backToSignIn();
        },
      );
    } else if (state is ForgotPasswordErrorState) {
      Navigator.pop(context);
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: 'Tentar novamente',
      );
    }
  }

  // Volta para o login; se a tela foi aberta direto (ex: a partir de um link),
  // não há tela anterior, então abre o login no lugar dela.
  void _backToSignIn() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, NamedRoute.signIn);
    }
  }

  void _onSendButtonPressed() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid) {
      _controller.sendResetLink(_emailController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.greenlightOne),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          const SizedBox(height: 16),
          const Icon(
            Icons.lock_reset,
            size: 72,
            color: AppColors.greenlightOne,
          ),
          const SizedBox(height: 16),
          Text(
            'Esqueceu a senha?',
            textAlign: TextAlign.center,
            style: AppTextStyles.midText36.copyWith(
              color: AppColors.greenlightOne,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Digite o e-mail da sua conta e enviaremos um link para você criar uma nova senha.',
              textAlign: TextAlign.center,
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: CustomTextFormField(
              key: Keys.forgotPasswordEmailField,
              controller: _emailController,
              labelText: 'Seu e-mail',
              hintText: 'email@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: Validator.validateEmail,
              textInputAction: TextInputAction.done,
              onEditingComplete: _onSendButtonPressed,
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
              key: Keys.forgotPasswordSendLinkButton,
              text: 'Enviar link',
              onPressed: _onSendButtonPressed,
            ),
          ),
          TextButton(
            onPressed: _backToSignIn,
            child: Text(
              'Lembrei a senha, voltar para o login',
              style: AppTextStyles.smallText.copyWith(
                color: AppColors.greenlightOne,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
