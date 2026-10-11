import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/local_photo.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'profile_controller.dart';
import 'profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<ProfileController>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isProcessing = false;

  String? _id;
  PhotoChange? _photo;
  final _media = locator.get<LocalMediaService>();
  String? _currentRole;
  // O CPF só pode ser informado uma vez (identifica a conta na equipe)
  bool _cpfLocked = false;

  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
  }

  // Função responsável por preencher os dados automaticamente ao entrar na tela
  void _fillFields(UserModel profile) {
    _id = profile.id;
    _currentRole = profile.role;
    _cpfLocked = (profile.cpf ?? '').isNotEmpty;

    _nameController.text = profile.name ?? '';
    _emailController.text = profile.email ?? '';
    _cpfController.text = _cpfLocked ? Formatters.cpf(profile.cpf!) : '';
    _phoneController.text = profile.phone ?? '';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isProcessing = true);

    final updatedProfile = UserModel(
      id: _id!,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      cpf: _cpfLocked ? null : _cpfController.text.trim(),
      password: null,
      role: _currentRole,
      phone: _phoneController.text.trim(),
    );

    final result = await _controller.saveProfile(
      updatedProfile,
      newPassword: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (!result.ok) {
      context.showErrorSnackBar(result.message);
      return;
    }
    // A foto fica só neste aparelho
    try {
      await _media.applyPhotoChange(MediaKind.profile, _id!, _photo);
    } catch (e) {
      debugPrint("Erro ao salvar a foto do perfil: $e");
      if (mounted) context.showErrorSnackBar("Não foi possível salvar a foto.");
    }
    if (!mounted) return;
    // Mostra o aviso na tela anterior, depois de fechar esta
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.greenlightOne,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meu Perfil")),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          final state = _controller.state;

          if (state is ProfileLoadingState || _isProcessing) {
            return const Center(child: CustomCircularProgressIndicator());
          }

          if (state is ProfileErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is ProfileSuccessState) {
            // Garante que o preenchimento ocorra apenas na primeira vez que a tela carrega
            if (_id == null) {
              _fillFields(state.profile);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PhotoEditor(
                      kind: MediaKind.profile,
                      id: _id,
                      change: _photo,
                      onChanged: (change) => setState(() => _photo = change),
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: StatusChip(
                        label: _currentRole == 'colaborador'
                            ? 'Colaborador'
                            : 'Produtor',
                        icon: _currentRole == 'colaborador'
                            ? Icons.badge_rounded
                            : Icons.agriculture_rounded,
                        color: AppColors.primary,
                        background: AppColors.primarySoft,
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "Nome completo",
                      validator: Validator.validateName,
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _emailController,
                      labelText: "E-mail de acesso",
                      keyboardType: TextInputType.emailAddress,
                      validator: Validator.validateEmail,
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _cpfController,
                      labelText: "CPF",
                      enabled: !_cpfLocked,
                      helperText: _cpfLocked
                          ? "O CPF não pode ser alterado"
                          : null,
                      keyboardType: TextInputType.number,
                      // Opcional, mas se informado precisa ser um CPF válido
                      validator: (v) => _cpfLocked || (v ?? '').trim().isEmpty
                          ? null
                          : Validator.validateCPF(v),
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _phoneController,
                      labelText: "Telefone / WhatsApp",
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          String numeros = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numeros.length < 10) {
                            return "Insira o DDD e o número";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: "Nova senha (deixe em branco para manter)",
                      helperText:
                          "Mínimo de 8 caracteres, com maiúscula, minúscula e número",
                      obscureText: true,
                      // Mesma regra do cadastro; vazio mantém a senha atual
                      validator: (v) => (v ?? '').isEmpty
                          ? null
                          : Validator.validatePassword(v),
                    ),
                    const SizedBox(height: 32),

                    PrimaryButton(text: "Salvar Alterações", onPressed: _save),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
