import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/services.dart';
import 'sign_in_state.dart';

class SignInController extends SafeChangeNotifier {
  SignInController({
    required AuthService authService,
    required SecureStorageService secureStorageService,
  }) : _secureStorageService = secureStorageService,
       _authService = authService;

  final AuthService _authService;
  final SecureStorageService _secureStorageService;

  SignInState _state = SignInStateInitial();

  SignInState get state => _state;

  void _changeState(SignInState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    bool keepConnected = true,
  }) async {
    _changeState(SignInStateLoading());

    final result = await _authService.signIn(email: email, password: password);

    await result.fold(
      (error) async => _changeState(SignInStateError(error.message)),
      (data) async {
        await _secureStorageService.write(
          key: SecureStorageService.currentUserKey,
          value: data.toJson(),
        );
        // Lido pelo Splash para decidir se mantém a sessão ao reabrir o app
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('keepConnected', keepConnected);

        // O perfil (produtor ou colaborador) já vem do cadastro lido no login
        _changeState(SignInStateSuccess(isCollaborator: data.isCollaborator));
      },
    );
  }
}
