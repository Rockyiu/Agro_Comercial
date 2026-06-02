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

  // Alterado de SignUp para signUp (padrão camelCase)
  Future<void> signUp({
    required String name,
    required String email,
    required String cpf,
    required String password,
    required String role,
  }) async {
    final secureStorage = SecureStorageService();
    _changeState(SignUpLoadingState());

    try {
      final result = await _service.signUp(
        name: name,
        email: email,
        cpf: cpf,
        password: password,
        role: role,
      );

      // Usando o fold para desempacotar o DataResult
      result.fold((error) => _changeState(SignUpErrorState(error.message)), (
        user,
      ) async {
        await secureStorage.write(key: "CURRENT_USER", value: user.toJson());
        _changeState(SignUpSuccessState());
      });
    } catch (e) {
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
