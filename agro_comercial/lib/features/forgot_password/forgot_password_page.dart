import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/auth_scaffold.dart';
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
    return AuthScaffold(
      title: 'Esqueceu a senha?',
      subtitle:
          'Digite o e-mail da sua conta e enviaremos um link para você criar uma nova senha.',
      children: [
        Form(
          key: _formKey,
          child: CustomTextFormField(
            key: Keys.forgotPasswordEmailField,
            controller: _emailController,
            labelText: 'E-mail',
            hintText: 'email@email.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: Validator.validateEmail,
            textInputAction: TextInputAction.done,
            onEditingComplete: _onSendButtonPressed,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: PrimaryButton(
            key: Keys.forgotPasswordSendLinkButton,
            text: 'Enviar link',
            icon: Icons.send_rounded,
            onPressed: _onSendButtonPressed,
          ),
        ),
        TextButton(
          onPressed: _backToSignIn,
          child: const Text('Lembrei a senha, voltar para o login'),
        ),
      ],
    );
  }
}
