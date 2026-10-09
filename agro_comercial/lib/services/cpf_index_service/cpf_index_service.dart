import 'package:cloud_firestore/cloud_firestore.dart';

// Conta dona de um CPF
class CpfOwner {
  final String uid;
  final String role;

  const CpfOwner({required this.uid, required this.role});
}

class CpfAlreadyInUseException implements Exception {
  const CpfAlreadyInUseException();

  @override
  String toString() => 'Este CPF já está cadastrado em outra conta.';
}

// Índice "CPF -> conta" (coleção cpf_index/{cpf}).
//
// Garante um CPF por conta e permite ao produtor achar o colaborador pelo
// CPF exato sem poder listar os cadastros de todos os usuários (as regras do
// Firestore liberam ler um CPF específico, mas não listar a coleção).
//
// As regras exigem que o índice e o CPF do cadastro (users/{uid}) sejam
// gravados juntos e iguais, por isso o registro é feito dentro de um lote.
class CpfIndexService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String normalize(String cpf) => cpf.replaceAll(RegExp(r'[^0-9]'), '');

  DocumentReference<Map<String, dynamic>> _doc(String cpf) =>
      _firestore.collection('cpf_index').doc(normalize(cpf));

  Future<CpfOwner?> findOwner(String cpf) async {
    if (normalize(cpf).length != 11) return null;
    final data = (await _doc(cpf).get()).data();
    if (data == null) return null;
    return CpfOwner(uid: data['uid'] as String, role: data['role'] as String);
  }

  // Confere se o CPF pode ser usado pela conta [uid]. Lança
  // [CpfAlreadyInUseException] se ele for de outra conta e devolve true se
  // já estiver registrado para esta mesma conta.
  Future<bool> ensureAvailable({
    required String cpf,
    required String uid,
  }) async {
    final owner = await findOwner(cpf);
    if (owner == null) return false;
    if (owner.uid != uid) throw const CpfAlreadyInUseException();
    return true;
  }

  // Registra o CPF no mesmo lote que grava o cadastro do usuário
  void addClaimToBatch(
    WriteBatch batch, {
    required String cpf,
    required String uid,
    required String role,
  }) {
    batch.set(_doc(cpf), {'uid': uid, 'role': role});
  }

  // Contas antigas (cadastro já tem o CPF): registra só o índice
  Future<void> claimExisting({
    required String cpf,
    required String uid,
    required String role,
  }) async {
    if (await ensureAvailable(cpf: cpf, uid: uid)) return;
    await _doc(cpf).set({'uid': uid, 'role': role});
  }
}
