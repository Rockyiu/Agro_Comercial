import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/user_model.dart';
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
  String? _imageUrl;
  String? _currentRole;
  String? _currentPassword;

  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
  }

  // Função responsável por preencher os dados automaticamente ao entrar na tela
  void _fillFields(UserModel profile) {
    _id = profile.id;
    _imageUrl = profile.imageUrl;
    _currentRole = profile.role;
    _currentPassword = profile.password;

    _nameController.text = profile.name ?? '';
    _emailController.text = profile.email ?? '';
    _cpfController.text = profile.cpf ?? '';
    _phoneController.text = profile.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Meu Perfil",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                  style: const TextStyle(color: Colors.red),
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
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.greenlightOne.withValues(
                              alpha: 0.1,
                            ),
                            backgroundImage: _imageUrl != null
                                ? NetworkImage(_imageUrl!)
                                : null,
                            child: _imageUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 64,
                                    color: AppColors.greenlightOne,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: AppColors.greenlightOne,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "O upload de imagem será integrado em breve!",
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    CustomTextFormField(
                      controller: _nameController,
                      labelText: "NOME COMPLETO",
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return "O nome é obrigatório";
                        if (v.trim().split(' ').length < 2)
                          return "Informe nome e sobrenome";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _emailController,
                      labelText: "E-MAIL DE ACESSO",
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return "O e-mail é obrigatório";
                        // Validação nativa de formato de E-mail
                        final bool emailValid = RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                        ).hasMatch(v);
                        if (!emailValid) return "Insira um e-mail válido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _cpfController,
                      labelText: "CPF DO PRODUTOR",
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          // Remove pontos e traços para contar apenas os números
                          String numeros = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numeros.length != 11) {
                            return "O CPF deve conter 11 dígitos";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _phoneController,
                      labelText: "TELEFONE / WHATSAPP",
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          String numeros = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (numeros.length < 10)
                            return "Insira o DDD e o número";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextFormField(
                      controller: _passwordController,
                      labelText: "NOVA SENHA (DEIXE EM BRANCO PARA MANTER)",
                      obscureText: true,
                      validator: (v) {
                        // Só valida se o usuário decidiu digitar uma nova senha
                        if (v != null && v.isNotEmpty && v.length < 6) {
                          return "A nova senha deve ter no mínimo 6 caracteres";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: "Salvar Alterações",
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => _isProcessing = true);

                          final updatedProfile = UserModel(
                            id: _id!,
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            cpf: _cpfController.text.trim(),
                            password: _passwordController.text.isNotEmpty
                                ? _passwordController.text
                                : _currentPassword,
                            role: _currentRole,
                            phone: _phoneController.text.trim(),
                            imageUrl: _imageUrl,
                          );

                          final success = await _controller.saveProfile(
                            updatedProfile,
                            newPassword: _passwordController.text,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          setState(() => _isProcessing = false);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Perfil atualizado com sucesso!"),
                                backgroundColor: AppColors.greenlightOne,
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            if (_controller.state is ProfileErrorState) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    (_controller.state as ProfileErrorState)
                                        .message,
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 6),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
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
