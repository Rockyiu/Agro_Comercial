// lib/common/models/app_exception.dart

abstract class AppException implements Exception {
  final String message;
  const AppException({required this.message});
}

class GeneralException extends AppException {
  const GeneralException()
    : super(message: "Ocorreu um erro. Tente novamente.");
}

class AuthException extends AppException {
  final String code;

  AuthException({required this.code})
    : super(message: _translateAuthError(code));

  // Tradutor automático de erros do Firebase!
  static String _translateAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha inválidos.';
      case 'email-already-in-use':
        return 'Este e-mail já está em uso.';
      case 'weak-password':
        return 'A senha escolhida é muito fraca.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      default:
        return 'Erro de autenticação. Verifique os dados e tente novamente.';
    }
  }
}
