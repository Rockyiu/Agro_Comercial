abstract class ResetPasswordState {}

class ResetPasswordInitialState extends ResetPasswordState {}

// Validando o código do link recebido por e-mail
class ResetPasswordVerifyingState extends ResetPasswordState {}

// Link válido: mostra o formulário de nova senha
class ResetPasswordReadyState extends ResetPasswordState {}

// Link expirado, já utilizado ou incompleto
class ResetPasswordInvalidLinkState extends ResetPasswordState {
  final String message;
  ResetPasswordInvalidLinkState(this.message);
}

// Salvando a nova senha
class ResetPasswordLoadingState extends ResetPasswordState {}

class ResetPasswordSuccessState extends ResetPasswordState {}

class ResetPasswordErrorState extends ResetPasswordState {
  final String message;
  ResetPasswordErrorState(this.message);
}
