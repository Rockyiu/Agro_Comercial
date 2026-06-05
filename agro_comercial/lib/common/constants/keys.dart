import 'package:flutter/foundation.dart';

class Keys {
  Keys._();

  // Sign up page (Cadastro)
  static const signUpListView = Key('sign_up_listview');
  static const signUpNameField = Key('sign_up_name_field');
  static const signUpEmailField = Key('sign_up_email_field');
  static const signUpCpfField = Key('sign_up_cpf_field');
  static const signUpPasswordField = Key('sign_up_password_field');
  static const signUpConfirmPasswordField = Key(
    'sign_up_confirm_password_field',
  );
  static const signUpButton = Key('sign_up_button');
  static const signUpAlreadyHaveAccountButton = Key(
    'sign_up_already_have_account_button',
  );

  // Farm Registration (Cadastro da Fazenda)
  static const farmRegistrationNameField = Key('farm_registration_name_field');
  static const farmRegistrationAreaField = Key('farm_registration_area_field');
  static const farmRegistrationSaveButton = Key(
    'farm_registration_save_button',
  );

  // Sign in page (Login)
  static const signInListView = Key('sign_in_listview');
  static const signInEmailField = Key('sign_in_email_field');
  static const signInPasswordField = Key('sign_in_password_field');
  static const signInButton = Key('sign_in_button');
  static const signInDontHaveAccountButton = Key(
    'sign_in_dont_have_account_button',
  );

  // Forgot password page (Esqueci a Senha)
  static const forgotPasswordButton = Key('forgot_password_button');
  static const forgotPasswordEmailField = Key('forgot_password_email_field');
  static const forgotPasswordSendLinkButton = Key(
    'forgot_password_send_link_button',
  );

  // App bottom bar items (Menu de baixo - Futuro)
  static const homePageBottomAppBarItem = Key('home_page_bottom_app_bar_item');
  static const operationsPageBottomAppBarItem = Key(
    'operations_page_bottom_app_bar_item',
  );
  static const inventoryPageBottomAppBarItem = Key(
    'inventory_page_bottom_app_bar_item',
  );
  static const profilePageBottomAppBarItem = Key(
    'profile_page_bottom_app_bar_item',
  );
}
