import 'package:flutter/foundation.dart';

import '../../services/services.dart';
import 'forgot_password_state.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController(this._authService);

  final AuthService _authService;

  ForgotPasswordState _state = ForgotPasswordInitialState();
  ForgotPasswordState get state => _state;

  void _changeState(ForgotPasswordState newState) {
    _state = newState;
    notifyListeners();
  }

  // Pede ao Firebase para enviar o e-mail com o link de redefinição de senha
  Future<void> sendResetLink(String email) async {
    _changeState(ForgotPasswordLoadingState());

    final result = await _authService.forgotPassword(email);

    result.fold(
      (error) => _changeState(ForgotPasswordErrorState(error.message)),
      (_) => _changeState(ForgotPasswordSuccessState(email.trim())),
    );
  }
}
