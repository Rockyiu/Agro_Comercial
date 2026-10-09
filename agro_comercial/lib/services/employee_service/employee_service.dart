import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_comercial/common/models/user_model.dart';
import 'package:agro_comercial/services/cpf_index_service/cpf_index_service.dart';

class EmployeeNotFoundException implements Exception {
  final String message;
  const EmployeeNotFoundException(this.message);

  @override
  String toString() => message;
}

class EmployeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CpfIndexService _cpfIndexService;

  EmployeeService(this._cpfIndexService);

  // 1. Busca apenas os colaboradores vinculados a esta FAZENDA
  Future<List<UserModel>> getEmployees(String farmId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('farmId', isEqualTo: farmId)
        .where('role', isEqualTo: 'colaborador')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    }).toList();
  }

  // Busca o nome de cada usuário pelo UID (usado para mostrar quem registrou
  // cada atividade). Lê pelo ID do documento, então funciona mesmo para
  // colaboradores que já foram desvinculados da fazenda.
  // Cada nome é buscado de forma independente: se um falhar (ex: colaborador
  // removido da equipe e sem permissão de leitura), os demais aparecem.
  Future<Map<String, String>> getUserNames(Iterable<String> userIds) async {
    Future<(String, String?)> nameOf(String id) async {
      try {
        final doc = await _firestore.collection('users').doc(id).get();
        return (id, doc.data()?['name'] as String?);
      } catch (_) {
        return (id, null);
      }
    }

    final names = await Future.wait(userIds.toSet().map(nameOf));
    return {
      for (final (id, name) in names)
        if (name != null && name.isNotEmpty) id: name,
    };
  }

  // 2. Vincula à fazenda o colaborador dono do CPF e devolve o nome dele.
  //
  // Para não vincular a pessoa errada (CPF digitado errado, ou alguém que
  // criou conta com o CPF de outro), confere que:
  // - a conta é de colaborador (não de produtor);
  // - o primeiro nome da conta é o mesmo informado pelo produtor;
  // - ele não pertence à equipe de outra fazenda.
  Future<String> inviteEmployee(String name, String cpf, String farmId) async {
    final uid = await _findCollaboratorUid(cpf);
    final userRef = _firestore.collection('users').doc(uid);
    final Map<String, dynamic>? data;
    try {
      data = (await userRef.get()).data();
    } on FirebaseException catch (e) {
      // As regras só liberam ler colaboradores sem fazenda ou da sua equipe
      if (e.code == 'permission-denied') throw _otherFarmError;
      rethrow;
    }
    if (data == null) throw const EmployeeNotFoundException(_notFoundMessage);

    final accountName = (data['name'] as String?) ?? '';
    if (_firstName(accountName) != _firstName(name)) {
      throw const EmployeeNotFoundException(
        "O nome informado não confere com o cadastro deste CPF. Confira o CPF e o nome do colaborador.",
      );
    }

    final currentFarmId = data['farmId'] as String?;
    if (currentFarmId == farmId) {
      throw const EmployeeNotFoundException(
        "Este colaborador já faz parte da sua equipe.",
      );
    }
    if (currentFarmId != null && currentFarmId.isNotEmpty) {
      throw _otherFarmError;
    }

    await userRef.update({'farmId': farmId});
    return accountName;
  }

  static const _otherFarmError = EmployeeNotFoundException(
    "Este colaborador já faz parte da equipe de outra fazenda. Peça para o responsável removê-lo antes.",
  );

  static const _notFoundMessage =
      "Nenhum colaborador encontrado com este CPF. Peça para ele criar uma conta no app primeiro.";

  Future<String> _findCollaboratorUid(String cpf) async {
    final owner = await _cpfIndexService.findOwner(cpf);
    if (owner != null) {
      if (owner.role != 'colaborador') {
        throw const EmployeeNotFoundException(
          "Este CPF pertence a uma conta de produtor, não de colaborador.",
        );
      }
      return owner.uid;
    }
    return _findLegacyCollaboratorUid(cpf);
  }

  // Contas antigas, criadas antes do índice de CPF e que ainda não entraram
  // no app atualizado. Depois que as regras de segurança forem publicadas
  // essa consulta é negada e o colaborador precisa abrir o app uma vez.
  Future<String> _findLegacyCollaboratorUid(String cpf) async {
    QuerySnapshot<Map<String, dynamic>> query;
    try {
      query = await _firestore
          .collection('users')
          .where('cpf', isEqualTo: CpfIndexService.normalize(cpf))
          .where('role', isEqualTo: 'colaborador')
          .limit(2)
          .get();
    } on FirebaseException {
      throw const EmployeeNotFoundException(
        "$_notFoundMessage Se ele já tem conta, peça para entrar no app uma vez e tente de novo.",
      );
    }
    if (query.docs.isEmpty) {
      throw const EmployeeNotFoundException(_notFoundMessage);
    }
    if (query.docs.length > 1) {
      throw const EmployeeNotFoundException(
        "Há mais de uma conta com este CPF. Entre em contato com o suporte.",
      );
    }
    return query.docs.single.id;
  }

  // Primeiro nome sem acentos e sem diferença de maiúsculas
  static String _firstName(String name) {
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c', //
    };
    final first = name.trim().toLowerCase().split(RegExp(r'\s+')).first;
    return first.split('').map((c) => accents[c] ?? c).join();
  }

  // Libera ou bloqueia o registro de Produção/Colheita para o colaborador
  Future<void> setHarvestPermission(String userId, bool allowed) async {
    await _firestore.collection('users').doc(userId).update({
      'canRegisterHarvest': allowed,
    });
  }

  // O colaborador logado foi liberado para registrar Produção/Colheita?
  Future<bool> hasHarvestPermission(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['canRegisterHarvest'] == true;
  }

  // Campos apagados ao desvincular: a liberação não acompanha o colaborador
  // se ele for vinculado depois a outra fazenda
  static final _unlinkFields = {
    'farmId': FieldValue.delete(),
    'canRegisterHarvest': FieldValue.delete(),
  };

  // 3. Remove o acesso (desvincula da fazenda)
  Future<void> removeEmployeeAccess(UserModel employee) async {
    if (employee.id != null) {
      await _firestore
          .collection('users')
          .doc(employee.id)
          .update(_unlinkFields);
    }
  }

  // 4. Exclui vários colaboradores da fazenda de uma vez
  Future<void> removeMultipleEmployees(List<UserModel> employees) async {
    final batch = _firestore.batch();
    for (var emp in employees) {
      if (emp.id != null) {
        final docRef = _firestore.collection('users').doc(emp.id);
        batch.update(docRef, _unlinkFields);
      }
    }
    await batch.commit();
  }
}
