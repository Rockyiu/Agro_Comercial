import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';
import 'package:agro_comercial/services/cpf_index_service/cpf_index_service.dart';
import 'package:agro_comercial/services/secure_storage.dart';

class SignUpController extends SafeChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _secureStorageService;

  SignUpController(this._authService, this._secureStorageService);

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
      final result = await _authService.signUp(
        name: name.trim(),
        email: email.trim(),
        // O CPF é salvo só com números (sem pontos e traço)
        cpf: CpfIndexService.normalize(cpf),
        password: password,
        role: role,
      );

      await result.fold(
        (error) async => _changeState(SignUpErrorState(error.message)),
        (user) async {
          // Mantém a sessão: ao reabrir o app o Splash entra direto
          await _secureStorageService.write(
            key: SecureStorageService.currentUserKey,
            value: user.toJson(),
          );
          _changeState(SignUpSuccessState());
        },
      );
    } catch (e) {
      _changeState(SignUpErrorState("Erro ao criar a conta. Tente novamente."));
    }
  }
}
