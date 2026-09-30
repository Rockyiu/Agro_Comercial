import 'package:get_it/get_it.dart';

// Serviços
import 'services/auth_service/auth_service.dart';
import 'services/auth_service/firebase_auth_service.dart';
import 'services/bookkeeping_service/bookkeeping_service.dart';
import 'services/cost_service/cost_service.dart';
import 'services/employee_service/employee_service.dart';
import 'services/farm_service/farm_service.dart';
import 'services/field_operation_service/field_operation_service.dart';
import 'services/invoice_service/invoice_local_service.dart';
import 'services/machine_service/machine_service.dart';
import 'services/operation_service/operation_service.dart';
import 'services/product_service/product_service.dart';
import 'services/profile_service/profile_service.dart';
import 'services/secure_storage.dart';
import 'services/stock_service/stock_service.dart';
import 'services/warehouse_service/warehouse_service.dart';

// Controllers
import 'features/cash_book/bookkeeping_controller.dart';
import 'features/cash_book/cash_book_year_controller.dart';
import 'features/cash_book/consolidation_controller.dart';
import 'features/costs/cost_controller.dart';
import 'features/edit_machine/edit_machine_controller.dart';
import 'features/edit_warehouse/edit_warehouse_controller.dart';
import 'features/employee/employee_controller.dart';
import 'features/farm/farm_controller.dart';
import 'features/farm_registration/farm_registration_controller.dart';
import 'features/field_operations/field_operation_controller.dart';
import 'features/forgot_password/forgot_password_controller.dart';
import 'features/home/collaborator_home_controller.dart';
import 'features/home/home_controller.dart';
import 'features/invoices/invoice_controller.dart';
import 'features/operation/operation_controller.dart';
import 'features/profile/profile_controller.dart';
import 'features/register_machine/register_machine_controller.dart';
import 'features/register_product/product_controller.dart';
import 'features/register_warehouse/register_warehouse_controller.dart';
import 'features/reset_password/reset_password_controller.dart';
import 'features/sign_in/sign_in_controller.dart';
import 'features/sign_up/sign_up_controller.dart';
import 'features/splash/splash_controller.dart';
import 'features/warehouse/warehouse_controller.dart';
import 'features/warehouse/warehouse_details_controller.dart';

final locator = GetIt.instance;

void setupDependencies() {
  _registerServices();
  _registerControllers();
}

void _registerServices() {
  locator.registerFactory<SecureStorageService>(
    () => const SecureStorageService(),
  );
  locator.registerFactory<AuthService>(
    () => FirebaseAuthService(locator.get<SecureStorageService>()),
  );

  locator.registerFactory<FarmService>(() => FarmService());
  locator.registerFactory<ProfileService>(() => ProfileService());
  locator.registerFactory<EmployeeService>(() => EmployeeService());

  locator.registerFactory<WarehouseService>(() => WarehouseService());
  locator.registerFactory<MachineService>(() => MachineService());
  locator.registerFactory<ProductService>(() => ProductService());
  locator.registerFactory<StockService>(
    () => StockService(
      locator.get<WarehouseService>(),
      locator.get<MachineService>(),
      locator.get<ProductService>(),
    ),
  );

  locator.registerFactory<OperationService>(() => OperationService());
  locator.registerFactory<FieldOperationService>(() => FieldOperationService());

  locator.registerLazySingleton<CostService>(() => CostService());
  locator.registerLazySingleton<BookkeepingService>(() => BookkeepingService());
  // Singleton: mantém uma única conexão aberta com o banco local (SQLite)
  locator.registerLazySingleton<InvoiceLocalService>(
    () => InvoiceLocalService(),
  );
}

void _registerControllers() {
  // --- Singletons: estado compartilhado entre várias telas ---

  // Fazenda ativa selecionada pelo usuário
  locator.registerLazySingleton<FarmController>(
    () => FarmController(locator.get<FarmService>()),
  );
  locator.registerLazySingleton<WarehouseController>(
    () => WarehouseController(
      locator.get<WarehouseService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerLazySingleton<BookkeepingController>(
    () => BookkeepingController(locator.get<BookkeepingService>()),
  );
  // Ano-calendário do Livro Caixa (compartilhado entre as telas)
  locator.registerLazySingleton<CashBookYearController>(
    () => CashBookYearController(),
  );
  locator.registerLazySingleton<ConsolidationController>(
    () => ConsolidationController(
      locator.get<BookkeepingService>(),
      locator.get<CashBookYearController>(),
    ),
  );

  // --- Factories: uma instância nova para cada tela ---

  // Autenticação
  locator.registerFactory<SplashController>(
    () => SplashController(
      authService: locator.get<AuthService>(),
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
  locator.registerFactory<ForgotPasswordController>(
    () => ForgotPasswordController(locator.get<AuthService>()),
  );
  locator.registerFactory<ResetPasswordController>(
    () => ResetPasswordController(locator.get<AuthService>()),
  );

  // Home
  locator.registerFactory<HomeController>(
    () => HomeController(
      locator.get<OperationService>(),
      locator.get<FieldOperationService>(),
      locator.get<EmployeeService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerFactory<CollaboratorHomeController>(
    () => CollaboratorHomeController(
      locator.get<OperationService>(),
      locator.get<FieldOperationService>(),
      locator.get<FarmController>(),
    ),
  );

  // Fazenda, perfil e equipe
  locator.registerFactory<FarmRegistrationController>(
    () => FarmRegistrationController(locator.get<FarmService>()),
  );
  locator.registerFactory<ProfileController>(
    () => ProfileController(locator.get<ProfileService>()),
  );
  locator.registerFactory<EmployeeController>(
    () => EmployeeController(
      locator.get<EmployeeService>(),
      locator.get<FarmController>(),
    ),
  );

  // Armazém, máquinas e produtos
  locator.registerFactory<RegisterWarehouseController>(
    () => RegisterWarehouseController(
      locator.get<WarehouseService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerFactory<EditWarehouseController>(
    () => EditWarehouseController(locator.get<WarehouseService>()),
  );
  locator.registerFactory<WarehouseDetailsController>(
    () => WarehouseDetailsController(
      locator.get<MachineService>(),
      locator.get<ProductService>(),
    ),
  );
  locator.registerFactory<RegisterMachineController>(
    () => RegisterMachineController(
      locator.get<MachineService>(),
      locator.get<WarehouseService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerFactory<EditMachineController>(
    () => EditMachineController(locator.get<MachineService>()),
  );
  locator.registerFactory<ProductController>(
    () => ProductController(
      locator.get<ProductService>(),
      locator.get<FarmController>(),
    ),
  );

  // Operações, vistorias e aplicações
  locator.registerFactory<OperationController>(
    () => OperationController(
      locator.get<OperationService>(),
      locator.get<StockService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerFactory<FieldOperationController>(
    () => FieldOperationController(
      locator.get<FieldOperationService>(),
      locator.get<StockService>(),
      locator.get<FarmController>(),
    ),
  );

  // Custos e notas fiscais
  locator.registerFactory<CostController>(
    () => CostController(
      locator.get<CostService>(),
      locator.get<AuthService>(),
      locator.get<FarmController>(),
    ),
  );
  locator.registerFactory<InvoiceController>(
    () => InvoiceController(
      locator.get<InvoiceLocalService>(),
      locator.get<FarmController>(),
    ),
  );
}
