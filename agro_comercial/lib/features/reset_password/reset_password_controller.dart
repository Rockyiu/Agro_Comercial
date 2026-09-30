import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/common/models/app_exception.dart';

import '../../services/services.dart';
import 'reset_password_state.dart';

class ResetPasswordController extends SafeChangeNotifier {
  ResetPasswordController(this._authService);

  final AuthService _authService;

  ResetPasswordState _state = ResetPasswordInitialState();
  ResetPasswordState get state => _state;

  String? _code;

  // E-mail da conta dona do link (preenchido após validar o código)
  String? email;

  void _changeState(ResetPasswordState newState) {
    _state = newState;
    notifyListeners();
  }

  // Confere se o link do e-mail ainda é válido antes de mostrar o formulário
  Future<void> verifyCode({
    required String? mode,
    required String? code,
  }) async {
    if (mode != 'resetPassword' || code == null || code.isEmpty) {
      _changeState(
        ResetPasswordInvalidLinkState(
          'Este link não é válido para redefinir a senha. Solicite um novo.',
        ),
      );
      return;
    }

    _code = code;
    _changeState(ResetPasswordVerifyingState());

    final result = await _authService.verifyPasswordResetCode(code);

    result.fold(
      (error) => _changeState(ResetPasswordInvalidLinkState(error.message)),
      (data) {
        email = data;
        _changeState(ResetPasswordReadyState());
      },
    );
  }

  Future<void> resetPassword(String newPassword) async {
    final code = _code;
    if (code == null) return;

    _changeState(ResetPasswordLoadingState());

    final result = await _authService.confirmPasswordReset(
      code: code,
      newPassword: newPassword,
    );

    result.fold((error) {
      // Se o link expirou enquanto a pessoa digitava, não adianta tentar de novo
      if (error is AuthException &&
          (error.code == 'expired-action-code' ||
              error.code == 'invalid-action-code')) {
        _changeState(ResetPasswordInvalidLinkState(error.message));
      } else {
        _changeState(ResetPasswordErrorState(error.message));
      }
    }, (_) => _changeState(ResetPasswordSuccessState()));
  }
}
