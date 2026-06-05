import 'package:flutter/material.dart';

// Importação das nossas telas
import 'features/splash/splash_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/sign_in/sign_in_page.dart';
import 'features/sign_up/sign_up_page.dart';
import 'features/farm_registration/farm_registration_page.dart';
import 'features/home/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestão Rural',
      debugShowCheckedModeBanner:
          false, // Remove aquela faixa vermelha chata de "Debug"
      initialRoute: '/', // A rota raiz, que sempre começa no Splash
      // O "Mapa" de endereços do seu aplicativo
      routes: {
        '/': (context) => const SplashPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_up': (context) => const SignUpPage(),
        '/farm_registration': (context) => const FarmRegistrationPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
