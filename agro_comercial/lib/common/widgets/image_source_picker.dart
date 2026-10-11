import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Pergunta se a foto vem da câmera ou da galeria (e, se já houver foto,
// oferece removê-la). Devolve null se o usuário cancelar.
Future<PhotoChange?> showImageSourcePicker(
  BuildContext context, {
  bool canRemove = false,
}) async {
  final choice = await showModalBottomSheet<Object>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text(
                "Foto",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                "A foto fica salva somente neste aparelho.",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              title: "Tirar foto",
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              title: "Escolher da galeria",
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            if (canRemove)
              _SourceTile(
                icon: Icons.delete_outline_rounded,
                title: "Remover foto",
                danger: true,
                onTap: () => Navigator.pop(sheetContext, const PhotoRemoved()),
              ),
          ],
        ),
      ),
    ),
  );

  if (choice is PhotoRemoved) return choice;
  if (choice is! ImageSource) return null;

  try {
    // Reduz a foto: guardar a imagem original da câmera ocuparia muito espaço
    final picked = await ImagePicker().pickImage(
      source: choice,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    return picked == null ? null : PhotoPicked(picked.path);
  } catch (e) {
    debugPrint("Erro ao abrir a câmera/galeria: $e");
    if (context.mounted) {
      context.showErrorSnackBar(
        "Não foi possível abrir a câmera ou a galeria. Confira as permissões do app.",
      );
    }
    return null;
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: IconBadge(
        icon: icon,
        size: 40,
        color: color,
        background: danger ? AppColors.dangerSoft : AppColors.primarySoft,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: danger ? AppColors.danger : AppColors.ink,
        ),
      ),
    );
  }
}
