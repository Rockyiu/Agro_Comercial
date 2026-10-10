import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/constants/keys.dart';
import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/common/widgets/auth_scaffold.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';

import '../../locator.dart';
import 'reset_password_controller.dart';
import 'reset_password_state.dart';

// Aberta pelo link enviado por e-mail (Android, iOS ou Web).
// O Firebase adiciona na URL: ?mode=resetPassword&oobCode=CODIGO
class ResetPasswordPage extends StatefulWidget {
  final String? mode;
  final String? oobCode;

  const ResetPasswordPage({super.key, this.mode, this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _controller = locator.get<ResetPasswordController>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleStateChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.verifyCode(mode: widget.mode, code: widget.oobCode);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool _isShowingLoadingDialog = false;

  void _closeLoadingDialog() {
    if (_isShowingLoadingDialog) {
      _isShowingLoadingDialog = false;
      Navigator.pop(context);
    }
  }

  void _handleStateChange() {
    final state = _controller.state;

    if (state is ResetPasswordLoadingState) {
      _isShowingLoadingDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CustomCircularProgressIndicator(),
      );
    } else if (state is ResetPasswordSuccessState) {
      _closeLoadingDialog();
      customModalBottomSheet(
        context,
        content: 'Senha alterada com sucesso! Entre com a sua nova senha.',
        buttonText: 'Ir para o login',
        onPressed: _goToSignIn,
      );
    } else if (state is ResetPasswordErrorState) {
      _closeLoadingDialog();
      customModalBottomSheet(
        context,
        content: state.message,
        buttonText: 'Tentar novamente',
      );
    } else if (state is ResetPasswordInvalidLinkState) {
      // Pode acontecer ao salvar (link expirou), então fecha o loading se aberto
      _closeLoadingDialog();
    }
  }

  void _goToSignIn() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      NamedRoute.signIn,
      (route) => false,
    );
  }

  void _onSaveButtonPressed() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid) {
      _controller.resetPassword(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        if (state is ResetPasswordInitialState ||
            state is ResetPasswordVerifyingState) {
          return const Scaffold(body: CustomCircularProgressIndicator());
        }

        if (state is ResetPasswordInvalidLinkState) {
          return Scaffold(body: _buildInvalidLink(state.message));
        }

        return _buildForm();
      },
    );
  }

  Widget _buildForm() {
    final email = _controller.email;
    return AuthScaffold(
      title: 'Criar nova senha',
      subtitle: email != null
          ? 'Conta: $email'
          : 'Escolha uma nova senha para acessar sua conta.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              PasswordFormField(
                key: Keys.resetPasswordNewPasswordField,
                controller: _passwordController,
                labelText: 'Nova senha',
                hintText: 'Crie uma senha',
                validator: Validator.validatePassword,
                helperText:
                    'No mínimo 8 caracteres, com número, letra minúscula e maiúscula',
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              PasswordFormField(
                key: Keys.resetPasswordConfirmPasswordField,
                controller: _confirmPasswordController,
                labelText: 'Confirme a nova senha',
                hintText: 'Repita a senha',
                validator: (value) => Validator.validateConfirmPassword(
                  _passwordController.text,
                  value,
                ),
                textInputAction: TextInputAction.done,
                onEditingComplete: _onSaveButtonPressed,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: PrimaryButton(
            key: Keys.resetPasswordSaveButton,
            text: 'Salvar nova senha',
            icon: Icons.lock_reset_rounded,
            onPressed: _onSaveButtonPressed,
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidLink(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EmptyState(
              icon: Icons.link_off_rounded,
              title: 'Link inválido',
              message: message,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: PrimaryButton(
                text: 'Solicitar novo link',
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  NamedRoute.forgotPassword,
                ),
              ),
            ),
            TextButton(
              onPressed: _goToSignIn,
              child: Text(
                'Voltar para o login',
                style: AppTextStyles.smallText.copyWith(
                  color: AppColors.greenlightOne,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
