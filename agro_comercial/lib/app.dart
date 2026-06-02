import 'package:agro_comercial/common/constants/routes.dart';
import 'package:agro_comercial/features/home/home_page.dart';
import 'package:agro_comercial/features/onboarding/onboarding_page.dart';
import 'package:agro_comercial/features/sign_in/sign_in_page.dart';
import 'package:agro_comercial/features/sign_up/sign_up_page.dart';
import 'package:agro_comercial/features/splash/splash_page.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: NamedRoute.splash,
      routes: {
        NamedRoute.initial: (context) => const OnboardingPage(),
        NamedRoute.splash: (context) => const SplashPage(),
        NamedRoute.signUp: (context) => const SignUpPage(),
        NamedRoute.signIn: (context) => const SignInPage(),
        NamedRoute.home: (context) => const HomePage(),
      },
    );
  }
}
