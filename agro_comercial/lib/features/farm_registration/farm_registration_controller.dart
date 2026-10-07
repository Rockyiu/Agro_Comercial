import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/farm_model.dart';
import 'package:agro_comercial/common/utils/area_units.dart';
import 'package:agro_comercial/services/farm_service/farm_service.dart';
import 'farm_registration_state.dart';

class FarmRegistrationController extends SafeChangeNotifier {
  final FarmService _farmService;

  FarmRegistrationController(this._farmService);

  FarmRegistrationState _state = FarmRegistrationInitialState();

  FarmRegistrationState get state => _state;

  void _changeState(FarmRegistrationState newState) {
    _state = newState;
    notifyListeners();
  }

  // ATUALIZADO: Recebendo os novos parâmetros totalArea e plantedFields
  Future<void> saveFarm({
    required String name,
    required String cadPro,
    required String address,
    required String totalArea,
    required List<Map<String, dynamic>> plantedFields,
    String areaUnit = AreaUnits.hectare,
  }) async {
    _changeState(FarmRegistrationLoadingState());

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _changeState(FarmRegistrationErrorState("Usuário não logado."));
        return;
      }

      // Montando a nova fazenda com a estrutura atualizada
      final newFarm = FarmModel(
        name: name,
        cadPro: cadPro,
        address: address,
        totalArea: totalArea,
        plantedFields: plantedFields,
        ownerId: user.uid, // Vincula ao dono atual!
        areaUnit: areaUnit,
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
