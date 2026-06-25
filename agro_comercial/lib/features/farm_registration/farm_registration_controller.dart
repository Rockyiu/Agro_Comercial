import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/services/farm_service/farm_service.dart';
import 'farm_registration_state.dart';

class FarmRegistrationController extends ChangeNotifier {
  final FarmService _farmService;

  FarmRegistrationController(this._farmService);

  FarmRegistrationState _state = FarmRegistrationInitialState();

  FarmRegistrationState get state => _state;

  void _changeState(FarmRegistrationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> saveFarm({
    required String name,
    required String cadPro, // ADICIONADO
    required String address,
    required String area,
    required int numberOfPlots,
    required List<String?> plotCrops,
  }) async {
    _changeState(FarmRegistrationLoadingState());

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _changeState(FarmRegistrationErrorState("Usuário não logado."));
        return;
      }

      // Converte os talhões (remover nulos por segurança)
      List<String> cleanCrops = plotCrops
          .where((c) => c != null)
          .cast<String>()
          .toList();

      final newFarm = FarmModel(
        name: name,
        cadPro: cadPro,
        address: address,
        area: area,
        numberOfPlots: numberOfPlots,
        plotCrops: cleanCrops,
        ownerId: user.uid, // Vincula ao dono atual!
      );

      // Salva de verdade no Firebase
      await _farmService.createFarm(newFarm);

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
