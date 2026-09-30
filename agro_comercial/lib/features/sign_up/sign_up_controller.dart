import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/features/sign_up/sing_up_state.dart';
import 'package:agro_comercial/services/auth_service/auth_service.dart';

class SignUpController extends SafeChangeNotifier {
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

      // Salva a resposta em uma variável 'result' para analisarmos
      final result = await _authService.signUp(
        name: name,
        email: email,
        cpf: cleanCpf,
        password: password,
        role: role,
      );

      // Usando o método fold() do seu DataResult para lidar com a resposta
      result.fold(
        (error) {
          // Se deu erro no Firebase (ex: email repetido, senha fraca), avisa a tela
          _changeState(SignUpErrorState(error.message));
        },
        (user) {
          // Se deu tudo certo, comemoramos o sucesso e mandamos para a tela de Fazenda
          _changeState(SignUpSuccessState());
        },
      );
    } catch (e) {
      _changeState(SignUpErrorState(e.toString()));
    }
  }
}
