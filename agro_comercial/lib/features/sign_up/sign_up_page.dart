import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/utils/uppercase_text_formatter.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/custom_bottom_sheet.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/password_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/farm_registration/farm_registration_page.dart';
import 'package:agro_comercial/features/home/collaborator_home_page.dart';
import 'package:agro_comercial/features/sign_up/sign_up_controller.dart';
import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:agro_comercial/locator.dart';

import 'package:agro_comercial/common/widgets/auth_scaffold.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
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
    _signUpController.dispose();
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmRegistrationPage(),
            ),
          );
        } else {
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
    return AuthScaffold(
      title: 'Crie sua conta',
      subtitle:
          'Cadastre-se como produtor ou colaborador e comece a gerir a fazenda.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextFormField(
                controller: _nameController,
                labelText: "Nome completo",
                hintText: "Como está no documento",
                prefixIcon: Icons.person_outline_rounded,
                inputFormatters: [UpperCaseTextInputFormatter()],
                validator: Validator.validateName,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              CustomTextFormField(
                controller: _cpfController,
                labelText: "CPF",
                hintText: "Apenas números",
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: Validator.validateCPF,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              CustomTextFormField(
                controller: _emailController,
                labelText: "E-mail",
                hintText: "email@email.com",
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validator.validateEmail,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: _RoleSelector(
                  value: _selectedRole,
                  onChanged: (role) => setState(() => _selectedRole = role),
                ),
              ),
              PasswordFormField(
                controller: _passwordController,
                labelText: "Senha",
                hintText: "Crie uma senha",
                validator: Validator.validatePassword,
                helperText:
                    "No mínimo 8 caracteres, com número, letra minúscula e maiúscula",
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              PasswordFormField(
                labelText: "Confirme a senha",
                hintText: "Repita a senha",
                validator: (value) => Validator.validateConfirmPassword(
                  _passwordController.text,
                  value,
                ),
                textInputAction: TextInputAction.done,
                onEditingComplete: _onSignUpButtonPressed,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: PrimaryButton(
            text: 'Criar conta',
            icon: Icons.arrow_forward_rounded,
            onPressed: _onSignUpButtonPressed,
          ),
        ),
        AuthSwitchLink(
          question: 'Já tem uma conta?',
          action: 'Entrar',
          onPressed: () => Navigator.popAndPushNamed(context, '/sign_in'),
        ),
      ],
    );
  }
}

// Escolha do perfil da conta: produtor (dono das fazendas) ou colaborador
class _RoleSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Perfil da conta',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _RoleOption(
                icon: Icons.agriculture_rounded,
                title: 'Produtor',
                subtitle: 'Dono da fazenda',
                selected: value == 'admin',
                onTap: () => onChanged('admin'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleOption(
                icon: Icons.engineering_rounded,
                title: 'Colaborador',
                subtitle: 'Equipe de campo',
                selected: value == 'colaborador',
                onTap: () => onChanged('colaborador'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: selected
                            ? AppColors.primary
                            : AppColors.inkMuted,
                      ),
                      const Spacer(),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selected ? 1 : 0,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
