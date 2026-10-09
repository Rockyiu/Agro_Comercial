import 'package:flutter_test/flutter_test.dart';

import 'package:agro_comercial/common/models/user_model.dart';

void main() {
  group('Liberação de Produção/Colheita', () {
    test('é lida do cadastro do usuário (padrão: bloqueada)', () {
      expect(
        UserModel.fromMap({'role': 'colaborador'}).canRegisterHarvest,
        isFalse,
      );
      expect(
        UserModel.fromMap({
          'role': 'colaborador',
          'canRegisterHarvest': true,
        }).canRegisterHarvest,
        isTrue,
      );
    });

    test('salvar o perfil não grava nem apaga a liberação', () {
      final user = UserModel.fromMap({
        'role': 'colaborador',
        'canRegisterHarvest': true,
      });
      expect(user.toMap().containsKey('canRegisterHarvest'), isFalse);
      expect(
        user.copyWith(canRegisterHarvest: false).canRegisterHarvest,
        isFalse,
      );
    });
  });
}
