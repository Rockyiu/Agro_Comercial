import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/cpf_index_service/cpf_index_service.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CpfIndexService _cpfIndexService;

  ProfileService(this._cpfIndexService);

  Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      // O id do usuário é o id do documento (não fica salvo dentro dele)
      return UserModel.fromMap({...data, 'id': doc.id});
    }

    // Se não existir no banco de dados, gera um temporário com o que tem no Auth
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      cpf: '',
      password: null,
      role: 'admin', // role padrão caso não tenha
    );
  }

  // Salva os dados que o próprio usuário pode alterar. Devolve true quando
  // um e-mail de confirmação foi enviado para o novo endereço.
  //
  // Perfil (role), fazenda (farmId) e permissões NÃO são gravados aqui: eles
  // só mudam pelo cadastro e pela tela "Minha Equipe".
  Future<bool> updateProfile(UserModel profile, {String? newPassword}) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError("Usuário não autenticado.");

    // Senha e e-mail primeiro: podem exigir login recente e, se falharem,
    // nada mais é alterado
    if (newPassword != null && newPassword.isNotEmpty) {
      await user.updatePassword(newPassword);
    }

    // O e-mail só muda depois que o usuário clicar no link enviado a ele
    final newEmail = profile.email?.trim() ?? '';
    final emailChanged = newEmail.isNotEmpty && newEmail != user.email;
    if (emailChanged) await user.verifyBeforeUpdateEmail(newEmail);

    if (profile.name != user.displayName) {
      await user.updateDisplayName(profile.name);
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    final current = (await docRef.get()).data() ?? {};
    final data = <String, dynamic>{
      'name': profile.name,
      'phone': profile.phone,
    };

    final batch = _firestore.batch();

    // O CPF identifica a conta (vínculo com a fazenda): só pode ser informado
    // uma vez, por quem ainda não tem. Vai no mesmo lote do índice de CPF.
    final currentCpf = (current['cpf'] as String?) ?? '';
    final newCpf = CpfIndexService.normalize(profile.cpf ?? '');
    if (currentCpf.isEmpty && newCpf.length == 11) {
      final alreadyMine = await _cpfIndexService.ensureAvailable(
        cpf: newCpf,
        uid: user.uid,
      );
      if (!alreadyMine) {
        _cpfIndexService.addClaimToBatch(
          batch,
          cpf: newCpf,
          uid: user.uid,
          role: (current['role'] as String?) ?? profile.role ?? 'admin',
        );
      }
      data['cpf'] = newCpf;
    }

    batch.set(docRef, data, SetOptions(merge: true));
    await batch.commit();
    return emailChanged;
  }
}
