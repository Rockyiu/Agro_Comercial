import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Pergunta se a foto vem da câmera ou da galeria e devolve o arquivo
// escolhido (ou null se o usuário cancelar)
Future<File?> showImageSourcePicker(
  BuildContext context, {
  String cameraLabel = 'Tirar Foto (Câmera)',
  String galleryLabel = 'Escolher da Galeria',
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(cameraLabel),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(galleryLabel),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picked = await ImagePicker().pickImage(
    source: source,
    imageQuality: 70,
  );
  return picked == null ? null : File(picked.path);
}
