import 'package:agro_comercial/features/farm_registration/farm_registration_controller.dart';
import 'package:agro_comercial/features/field_operations/field_operation_controller.dart';
import 'package:agro_comercial/features/operation/operation_controller.dart';
import 'package:agro_comercial/features/profile/profile_controller.dart';
import 'package:agro_comercial/features/register_warehouse/register_warehouse_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_details_controller.dart';
import 'package:agro_comercial/features/register_machine/register_machine_controller.dart';
import 'package:agro_comercial/features/edit_machine/edit_machine_controller.dart';
import 'package:agro_comercial/features/edit_warehouse/edit_warehouse_controller.dart';
import 'package:agro_comercial/services/field_operation_service/field_operation_service.dart';
import 'package:agro_comercial/services/operation_service/operation_service.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'package:agro_comercial/services/profile_service/profile_service.dart';
import 'package:agro_comercial/services/warehouse_service/warehouse_service.dart';
import 'package:agro_comercial/services/machine_service/machine_service.dart';
import 'package:get_it/get_it.dart';

// Importação dos Serviços
import 'services/auth_service/auth_service.dart';
import 'services/auth_service/firebase_auth_service.dart';
import 'services/secure_storage.dart';

// Importação dos Controllers
import 'features/splash/splash_controller.dart';
import 'features/sign_in/sign_in_controller.dart';
import 'features/sign_up/sign_up_controller.dart';

final locator = GetIt.instance;

void setupDependencies() {
  // ==========================
  // Registro de Serviços
  // ==========================

  locator.registerFactory<AuthService>(() => FirebaseAuthService());
  locator.registerFactory<SecureStorageService>(
    () => const SecureStorageService(),
  );
  locator.registerFactory<WarehouseService>(() => WarehouseService());
  locator.registerFactory<MachineService>(() => MachineService());

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
    () => SignUpController(locator.get<AuthService>()),
  );

  locator.registerFactory<FarmRegistrationController>(
    () => FarmRegistrationController(),
  );

  locator.registerLazySingleton<WarehouseController>(
    () => WarehouseController(locator.get<WarehouseService>()),
  );

  locator.registerFactory<RegisterWarehouseController>(
    () => RegisterWarehouseController(locator.get<WarehouseService>()),
  );

  locator.registerFactory<WarehouseDetailsController>(
    () => WarehouseDetailsController(locator.get<MachineService>()),
  );

  locator.registerFactory<RegisterMachineController>(
    () => RegisterMachineController(
      locator.get<MachineService>(),
      locator.get<WarehouseService>(),
    ),
  );

  locator.registerFactory<EditMachineController>(
    () => EditMachineController(locator.get<MachineService>()),
  );

  locator.registerFactory<EditWarehouseController>(
    () => EditWarehouseController(locator.get<WarehouseService>()),
  );

  locator.registerFactory<ProductService>(() => ProductService());

  locator.registerFactory<FieldOperationService>(() => FieldOperationService());

  locator.registerFactory<FieldOperationController>(
    () => FieldOperationController(
      locator.get<FieldOperationService>(),
      locator.get<MachineService>(),
      locator.get<WarehouseService>(),
      locator.get<ProductService>(),
    ),
  );

  locator.registerFactory<OperationService>(() => OperationService());

  locator.registerFactory<OperationController>(
    () => OperationController(
      locator.get<OperationService>(),
      locator.get<MachineService>(),
      locator.get<WarehouseService>(),
      locator.get<ProductService>(),
    ),
  );

  locator.registerFactory<ProfileService>(() => ProfileService());

  // No bloco de "Registro de Controllers":
  locator.registerFactory<ProfileController>(
    () => ProfileController(locator.get<ProfileService>()),
  );
}
