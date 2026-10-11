import 'dart:io';

import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Tipo de foto guardada no aparelho
enum MediaKind {
  product('produtos'),
  machine('maquinas'),
  profile('perfil');

  final String folder;
  const MediaKind(this.folder);
}

// Fotos (produtos, máquinas, perfil) e comprovantes em PDF do Livro Caixa.
//
// Os arquivos ficam SOMENTE no aparelho, na pasta privada do app (outros
// apps não têm acesso), separados por usuário: nada vai para o Firebase.
// Cada arquivo é identificado pelo id do registro no banco (produto,
// máquina, usuário ou lançamento).
//
// Na web não há pasta do app: lá as fotos e comprovantes não ficam
// disponíveis ([isSupported] = false).
//
// As telas que mostram fotos escutam este serviço ([ChangeNotifier]) para
// atualizar quando uma foto é trocada ou removida.
class LocalMediaService extends ChangeNotifier {
  static const _receiptsFolder = 'comprovantes';

  bool get isSupported => !kIsWeb;

  // Ids vêm do Firestore/Auth (letras e números, sem "_", que separa o id
  // da data no nome do arquivo). Qualquer outra coisa é
  // recusada para nunca montar um caminho fora da pasta do app.
  static final _safeId = RegExp(r'^[A-Za-z0-9-]{1,128}$');

  // Pasta base e usuário logado (substituíveis nos testes)
  final Future<Directory> Function() _baseDir;
  final String? Function() _currentUserId;

  LocalMediaService({
    Future<Directory> Function()? baseDir,
    String? Function()? currentUserId,
  }) : _baseDir = baseDir ?? getApplicationDocumentsDirectory,
       _currentUserId =
           currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  Directory? _root;

  // Pasta do usuário logado: <documentos do app>/midia/<uid>
  Future<Directory> _userDir() async {
    final uid = _currentUserId() ?? 'sem_usuario';
    _root ??= await _baseDir();
    return Directory(p.join(_root!.path, 'midia', uid));
  }

  Future<Directory> _folder(String name) async {
    final dir = Directory(p.join((await _userDir()).path, name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  void _checkId(String id) {
    if (!_safeId.hasMatch(id)) throw ArgumentError.value(id, 'id');
  }

  // Versões do arquivo de um registro. O nome leva a data de gravação
  // ("<id>_<data>.jpg") para a tela não mostrar a foto antiga guardada em
  // cache depois de uma troca.
  Future<List<File>> _versions(String folder, String id) async {
    if (!isSupported || !_safeId.hasMatch(id)) return const [];
    final dir = await _folder(folder);
    final prefix = '${id}_';
    return [
      await for (final entity in dir.list())
        if (entity is File && p.basename(entity.path).startsWith(prefix))
          entity,
    ];
  }

  Future<File?> _latest(String folder, String id) async {
    final files = await _versions(folder, id);
    if (files.isEmpty) return null;
    files.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    return files.first;
  }

  Future<void> _save(
    String folder,
    String id,
    String extension,
    Future<void> Function(File target) write,
  ) async {
    if (!isSupported) return;
    _checkId(id);
    final old = await _versions(folder, id);
    final stamp = DateTime.now().millisecondsSinceEpoch.toString().padLeft(
      15,
      '0',
    );
    final target = File(
      p.join((await _folder(folder)).path, '${id}_$stamp.$extension'),
    );
    await write(target);
    // Só apaga a versão anterior depois que a nova foi gravada
    for (final file in old) {
      // (duas gravações no mesmo milissegundo geram o mesmo nome)
      if (file.path != target.path) await _deleteFile(file);
    }
    notifyListeners();
  }

  Future<void> _delete(String folder, Iterable<String> ids) async {
    if (!isSupported) return;
    var changed = false;
    for (final id in ids) {
      for (final file in await _versions(folder, id)) {
        await _deleteFile(file);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
    } catch (e) {
      debugPrint("Arquivo não apagado (${file.path}): $e");
    }
  }

  // --- Fotos ---------------------------------------------------------------

  Future<File?> image(MediaKind kind, String id) => _latest(kind.folder, id);

  // Copia a foto escolhida (câmera/galeria) para a pasta do app
  Future<void> saveImage(MediaKind kind, String id, String sourcePath) =>
      _save(kind.folder, id, 'jpg', (target) async {
        await File(sourcePath).copy(target.path);
      });

  Future<void> deleteImages(MediaKind kind, Iterable<String> ids) =>
      _delete(kind.folder, ids);

  // Grava a alteração feita no formulário (foto nova ou remoção) depois que
  // o registro [id] foi salvo no banco
  Future<void> applyPhotoChange(
    MediaKind kind,
    String id,
    PhotoChange? change,
  ) async {
    switch (change) {
      case PhotoPicked(:final path):
        await saveImage(kind, id, path);
      case PhotoRemoved():
        await deleteImages(kind, [id]);
      case null:
        break;
    }
  }

  // --- Comprovantes (PDF) do Livro Caixa ----------------------------------

  Future<File?> receipt(String entryId) => _latest(_receiptsFolder, entryId);

  Future<void> saveReceipt(String entryId, Uint8List bytes) =>
      _save(_receiptsFolder, entryId, 'pdf', (target) async {
        await target.writeAsBytes(bytes, flush: true);
      });

  Future<void> deleteReceipts(Iterable<String> entryIds) =>
      _delete(_receiptsFolder, entryIds);

  // Ids dos lançamentos que têm comprovante neste aparelho
  Future<Set<String>> receiptIds() async {
    if (!isSupported) return {};
    final dir = await _folder(_receiptsFolder);
    return {
      await for (final entity in dir.list())
        if (entity is File) _idOf(entity),
    };
  }

  static String _idOf(File file) {
    final name = p.basenameWithoutExtension(file.path);
    final separator = name.lastIndexOf('_');
    return separator == -1 ? name : name.substring(0, separator);
  }
}
