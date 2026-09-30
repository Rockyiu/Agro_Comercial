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
      case 'missing-email':
        return 'Informe o seu e-mail.';
      case 'expired-action-code':
        return 'Este link de redefinição expirou. Solicite um novo.';
      case 'invalid-action-code':
        return 'Este link de redefinição é inválido ou já foi usado. Solicite um novo.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique e tente novamente.';
      default:
        return 'Erro de autenticação. Verifique os dados e tente novamente.';
    }
  }
}
