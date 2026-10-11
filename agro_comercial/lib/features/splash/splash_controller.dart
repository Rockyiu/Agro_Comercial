import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/services.dart';
import 'splash_state.dart';

class SplashController extends SafeChangeNotifier {
  SplashController({
    required AuthService authService,
    required SecureStorageService secureStorageService,
  }) : _authService = authService,
       _secureStorageService = secureStorageService;

  final AuthService _authService;
  final SecureStorageService _secureStorageService;

  SplashState _state = SplashStateInitial();

  SplashState get state => _state;

  void _changeState(SplashState newState) {
    _state = newState;
    notifyListeners();
  }

  static bool _storedRoleIsCollaborator(String json) {
    try {
      return UserModel.fromJson(json).isCollaborator;
    } catch (_) {
      return false;
    }
  }

  Future<void> isUserLogged() async {
    final prefs = await SharedPreferences.getInstance();
    // Opção "Manter-me conectado" da tela de login (padrão: sim)
    final keepConnected = prefs.getBool('keepConnected') ?? true;

    final storedUser = await _secureStorageService.readOne(
      key: SecureStorageService.currentUserKey,
    );

    final isLogged =
        storedUser != null &&
        keepConnected &&
        await _authService.hasActiveSession();

    if (!isLogged) {
      // Limpa qualquer sessão que tenha sobrado (ex: não quis ficar conectado)
      if (storedUser != null) await _authService.signOut();
      _changeState(UnauthenticatedUser());
      return;
    }

    bool isCollaborator;
    try {
      isCollaborator = await _authService.isCurrentUserCollaborator();
    } catch (e) {
      // Sem conexão ao buscar o perfil: usa o perfil salvo no último login,
      // para o colaborador não cair na Home do produtor
      debugPrint("Erro ao verificar o perfil do usuário: $e");
      isCollaborator = _storedRoleIsCollaborator(storedUser);
    }
    _changeState(AuthenticatedUser(isCollaborator: isCollaborator));
  }
}
