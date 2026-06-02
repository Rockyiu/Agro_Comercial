import 'dart:developer';

import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';
import 'package:agro_comercial/services/secure_storage.dart';
import 'package:flutter/foundation.dart';

class SignUpController extends ChangeNotifier {
  final AuthService _service;

  SignUpController(this._service);

  SingUpState _state = SignUpinitialState();

  SingUpState get state => _state;

  void _changeState(SingUpState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> SignUp({
    required String name,
    required String email,
    required String cpf,
    required String password,
    required String role, // Parâmetro adicionado
  }) async {
    final secureStorage = SecureStorageService();
    _changeState(SignUpLoadingState());

    try {
      final user = await _service.signUp(
        name: name,
        email: email,
        cpf: cpf,
        password: password,
        role: role, // Repassando para o service
      );

      if (user.id != null) {
        await secureStorage.write(key: "CURRENT_USER", value: user.toJson());
        _changeState(SignUpSuccessState());
      } else {
        throw Exception();
      }
    } catch (e) {
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
