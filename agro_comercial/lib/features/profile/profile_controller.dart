import 'package:agro_comercial/common/models/app_exception.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/services/cpf_index_service/cpf_index_service.dart';
import 'package:agro_comercial/services/profile_service/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'profile_state.dart';

class ProfileController extends SafeChangeNotifier {
  final ProfileService _profileService;

  ProfileController(this._profileService);

  ProfileState _state = ProfileInitialState();
  ProfileState get state => _state;

  Future<void> loadProfile() async {
    _state = ProfileLoadingState();
    notifyListeners();
    try {
      final profile = await _profileService.getUserProfile();
      if (profile != null) {
        _state = ProfileSuccessState(profile);
      } else {
        _state = ProfileErrorState("Perfil não encontrado.");
      }
    } catch (e) {
      _state = ProfileErrorState("Erro ao carregar dados do perfil.");
    }
    notifyListeners();
  }

  // Salva o perfil e devolve a mensagem para mostrar ao usuário. Em caso de
  // erro o estado não muda, para o formulário (e o que foi digitado)
  // continuar na tela.
  Future<({bool ok, String message})> saveProfile(
    UserModel profile, {
    String? newPassword,
  }) async {
    try {
      final emailVerificationSent = await _profileService.updateProfile(
        profile,
        newPassword: newPassword,
      );
      await loadProfile();
      return (
        ok: true,
        message: emailVerificationSent
            ? "Perfil atualizado! Confirme o novo e-mail pelo link que enviamos para ele."
            : "Perfil atualizado com sucesso!",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return (
          ok: false,
          message:
              "Por segurança, para alterar e-mail ou senha saia da conta e entre novamente.",
        );
      }
      return (ok: false, message: AuthException(code: e.code).message);
    } on CpfAlreadyInUseException catch (e) {
      return (ok: false, message: e.toString());
    } catch (e) {
      debugPrint("Erro ao salvar o perfil: $e");
      return (ok: false, message: "Erro ao salvar o perfil. Tente novamente.");
    }
  }
}
