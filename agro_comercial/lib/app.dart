import 'package:flutter/material.dart';

import 'common/constants/routes.dart';
import 'common/themes/default_theme.dart';

// Importação das nossas telas
import 'features/splash/splash_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/sign_in/sign_in_page.dart';
import 'features/sign_up/sign_up_page.dart';
import 'features/forgot_password/forgot_password_page.dart';
import 'features/reset_password/reset_password_page.dart';
import 'features/farm_registration/farm_registration_page.dart';
import 'features/home/home_page.dart';
import 'features/home/collaborator_home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  // Links de ação do Firebase (ex: redefinir senha) chegam com parâmetros:
  // /auth/action?mode=resetPassword&oobCode=...
  // Como o nome da rota inclui a query, ela não bate com o mapa de "routes"
  // e cai aqui. Vale para o link aberto no Android, iOS e Web.
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '');
    if (uri == null) return null;

    if (uri.path == NamedRoute.authAction) {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => ResetPasswordPage(
          mode: uri.queryParameters['mode'],
          oobCode: uri.queryParameters['oobCode'],
        ),
      );
    }
    return null;
  }

  // Rota inicial: se o app foi aberto pelo link do e-mail, vai direto para a
  // tela de redefinir senha (sem o Splash por baixo, que redirecionaria o
  // usuário para o login/home). Caso contrário, começa sempre pelo Splash.
  static List<Route<dynamic>> _onGenerateInitialRoutes(String initialRoute) {
    final linkRoute = _onGenerateRoute(RouteSettings(name: initialRoute));
    if (linkRoute != null) return [linkRoute];

    return [
      MaterialPageRoute(
        settings: const RouteSettings(name: NamedRoute.initial),
        builder: (context) => const SplashPage(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Rural',
      theme: defaultTheme,
      debugShowCheckedModeBanner:
          false, // Remove aquela faixa vermelha chata de "Debug"
      initialRoute: '/', // A rota raiz, que sempre começa no Splash
      onGenerateInitialRoutes: _onGenerateInitialRoutes,
      onGenerateRoute: _onGenerateRoute,
      // O "Mapa" de endereços do seu aplicativo
      routes: {
        '/': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        NamedRoute.forgotPassword: (context) => const ForgotPasswordPage(),
        '/farm_registration': (context) => const FarmRegistrationPage(),
        '/home': (context) => const HomePage(),
        NamedRoute.collaboratorHome: (context) => const CollaboratorHomePage(),
      },
    );
  }
}
