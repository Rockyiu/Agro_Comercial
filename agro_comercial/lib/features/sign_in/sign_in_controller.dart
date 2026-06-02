import 'package:agro_comercial/features/sign_in/sign_in_state.dart';
import 'package:agro_comercial/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignInController extends ChangeNotifier {
  final AuthService _service;

  SignInController(this._service);

  SignInState _state = SingInStateInitial();

  SignInState get state => _state;

  void _changeState(SignInState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> SignUp({required String email, required String password}) async {
    _changeState(SignInStateLoading());

    try {
      await _service.signIn(email: email, password: password);
      _changeState(SignInStateSuccess());
    } catch (e) {
      _changeState(SignInStateError(e.toString()));
    }
  }
}
