import 'package:flutter/material.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/profile_service/profile_service.dart';

import 'profile_state.dart'; // ADICIONADO: Puxando as classes do arquivo correto

class ProfileController extends ChangeNotifier {
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

  Future<bool> saveProfile(UserModel profile, {String? newPassword}) async {
    try {
      await _profileService.updateProfile(profile, newPassword: newPassword);
      await loadProfile();
      return true;
    } catch (e) {
      _state = ProfileErrorState(
        "Erro de Segurança: Modificações de e-mail ou senha exigem que você faça login novamente.",
      );
      notifyListeners();
      return false;
    }
  }
}
