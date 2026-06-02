import 'package:flutter/foundation.dart';
import 'farm_registration_state.dart';

class FarmRegistrationController extends ChangeNotifier {
  FarmRegistrationState _state = FarmRegistrationInitialState();

  FarmRegistrationState get state => _state;

  void _changeState(FarmRegistrationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> saveFarm({
    required String name,
    required String address,
    required String area,
    required int numberOfPlots,
    required List<String?> plotCrops,
  }) async {
    _changeState(FarmRegistrationLoadingState());

    try {
      // Simulação de tempo de salvamento no servidor
      // Futuramente, substituiremos pela chamada do Firebase Firestore
      await Future.delayed(const Duration(seconds: 2));

      _changeState(FarmRegistrationSuccessState());
    } catch (e) {
      _changeState(
        FarmRegistrationErrorState(
          "Erro ao salvar a propriedade. Tente novamente.",
        ),
      );
    }
  }
}
