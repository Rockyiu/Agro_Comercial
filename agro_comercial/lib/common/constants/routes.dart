class NamedRoute {
  NamedRoute._();

  static const String initial = "/";
  static const String splash = "/splash";
  static const String signUp = "/sign_up";
  static const String signIn = "/sign_in";
  static const String home = "/home";
  static const String forgotPassword = "/forgot_password";
  // Link enviado por e-mail pelo Firebase (URL de ação personalizada).
  // Ex: https://agro-comercial.web.app/auth/action?mode=resetPassword&oobCode=...
  static const String authAction = "/auth/action";
}
