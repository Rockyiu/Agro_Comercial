import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';

class SignUpController extends ChangeNotifier {
  final AuthService _authService;

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
      // Limpa a formatação do CPF (remove pontos e traços)
      String cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

      // Faz o cadastro do usuário (Admin ou Colaborador) livremente
      await _authService.signUp(
        name: name,
        email: email,
        cpf: cleanCpf,
        password: password,
        role: role,
      );

      _changeState(SignUpSuccessState());
    } catch (e) {
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
