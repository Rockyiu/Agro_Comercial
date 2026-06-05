import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:flutter/foundation.dart';

import 'package:agro_comercial/services/auth_service/auth_service.dart';

class SignUpController extends ChangeNotifier {
  // A variável que vai receber o serviço
  final AuthService _authService;

  // O construtor exigindo o serviço (Isso resolve o erro do locator.dart!)
  SignUpController(this._authService);

  SingUpState _state = SignUpinitialState();
  SingUpState get state => _state;

  void _changeState(SingUpState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String cpf,
    required String password,
    required String role,
  }) async {
    _changeState(SignUpLoadingState());

    try {
      await _authService.signUp(
        name: name,
        email: email,
        cpf: cpf,
        password: password,
        role: role,
      );
      _changeState(SignUpSuccessState());
    } catch (e) {
      // Exibe o erro exato e real do Firebase na tela
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
