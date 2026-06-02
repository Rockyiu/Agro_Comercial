import 'package:get_it/get_it.dart';

// Importação dos Serviços
import 'services/auth_service/auth_service.dart';
import 'services/auth_service/firebase_auth_service.dart';
import 'services/secure_storage.dart';

// Importação dos Controllers
import 'features/splash/splash_controller.dart';
import 'features/sign_in/sign_in_controller.dart';
import 'features/sign_up/sign_up_controller.dart';

import 'features/farm_registration/farm_registration_controller.dart';

final locator = GetIt.instance;

void setupDependencies() {
  // ==========================
  // Registro de Serviços
  // ==========================

  locator.registerFactory<AuthService>(() => FirebaseAuthService());

  locator.registerFactory<SecureStorageService>(
    () => const SecureStorageService(),
  );

  // ==========================
  // Registro de Controllers
  // ==========================

  locator.registerFactory<SplashController>(
    () => SplashController(
      secureStorageService: locator.get<SecureStorageService>(),
    ),
  );

  locator.registerFactory<SignInController>(
    () => SignInController(
      authService: locator.get<AuthService>(),
      secureStorageService: locator.get<SecureStorageService>(),
    ),
  );

  locator.registerFactory<SignUpController>(
    // O SignUpController espera o AuthService como parâmetro posicional direto
    () => SignUpController(locator.get<AuthService>()),
  );

  locator.registerFactory<FarmRegistrationController>(
    () => FarmRegistrationController(),
  );
}
