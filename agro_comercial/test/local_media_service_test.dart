import 'dart:io';
import 'dart:typed_data';

import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late String uid;
  late LocalMediaService media;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('midia_teste');
    uid = 'usuarioA';
    media = LocalMediaService(
      baseDir: () async => root,
      currentUserId: () => uid,
    );
  });

  tearDown(() => root.delete(recursive: true));

  Future<String> fakePhoto(String content) async {
    final file = File('${root.path}/origem_$content.jpg');
    await file.writeAsString(content);
    return file.path;
  }

  test('foto nova substitui a anterior e some ao excluir', () async {
    var notifications = 0;
    media.addListener(() => notifications++);

    await media.applyPhotoChange(
      MediaKind.machine,
      'maq1',
      PhotoPicked(await fakePhoto('primeira')),
    );
    expect(
      await (await media.image(MediaKind.machine, 'maq1'))!.readAsString(),
      'primeira',
    );

    await media.saveImage(
      MediaKind.machine,
      'maq1',
      await fakePhoto('segunda'),
    );
    final current = await media.image(MediaKind.machine, 'maq1');
    expect(await current!.readAsString(), 'segunda');
    // Só a versão nova fica guardada
    expect(current.parent.listSync().whereType<File>().length, 1);

    await media.applyPhotoChange(
      MediaKind.machine,
      'maq1',
      const PhotoRemoved(),
    );
    expect(await media.image(MediaKind.machine, 'maq1'), isNull);
    expect(notifications, 3);
  });

  test('fotos de tipos e usuários diferentes não se misturam', () async {
    await media.saveImage(MediaKind.product, 'p1', await fakePhoto('produto'));

    expect(await media.image(MediaKind.machine, 'p1'), isNull);
    uid = 'usuarioB';
    expect(await media.image(MediaKind.product, 'p1'), isNull);
    uid = 'usuarioA';
    expect(await media.image(MediaKind.product, 'p1'), isNotNull);
  });

  test('id com caminho é recusado', () async {
    expect(
      () => media.saveImage(MediaKind.product, '../fora', 'x'),
      throwsArgumentError,
    );
    expect(await media.image(MediaKind.product, '../fora'), isNull);
  });

  test('comprovantes: lista os lançamentos que têm PDF', () async {
    final pdf = Uint8List.fromList('%PDF-1.4 teste'.codeUnits);
    await media.saveReceipt('lanc1', pdf);
    await media.saveReceipt('lanc2', pdf);

    expect(await media.receiptIds(), {'lanc1', 'lanc2'});
    expect(await (await media.receipt('lanc1'))!.readAsBytes(), pdf);

    await media.deleteReceipts(['lanc1']);
    expect(await media.receiptIds(), {'lanc2'});
  });
}
