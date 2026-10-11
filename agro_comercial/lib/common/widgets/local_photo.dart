import 'dart:io';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/widgets/image_source_picker.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:flutter/material.dart';

// Foto guardada no aparelho (produto, máquina ou perfil). Sem foto, mostra
// [placeholder]. Atualiza sozinha quando a foto é trocada.
class LocalPhoto extends StatefulWidget {
  final MediaKind kind;
  final String? id;
  final double size;
  final BorderRadius? borderRadius; // null = círculo
  final Widget placeholder;

  const LocalPhoto({
    super.key,
    required this.kind,
    required this.id,
    required this.size,
    required this.placeholder,
    this.borderRadius,
  });

  @override
  State<LocalPhoto> createState() => _LocalPhotoState();
}

class _LocalPhotoState extends State<LocalPhoto> {
  final _media = locator.get<LocalMediaService>();
  Future<File?>? _file;

  @override
  void initState() {
    super.initState();
    _file = _fetch();
    _media.addListener(_reload);
  }

  @override
  void didUpdateWidget(covariant LocalPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || oldWidget.kind != widget.kind) {
      _file = _fetch();
    }
  }

  Future<File?>? _fetch() {
    final id = widget.id;
    return id == null ? null : _media.image(widget.kind, id);
  }

  void _reload() => setState(() => _file = _fetch());

  @override
  void dispose() {
    _media.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _file,
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return widget.placeholder;
        return PhotoFrame(
          size: widget.size,
          borderRadius: widget.borderRadius,
          child: Image.file(
            file,
            key: ValueKey(file.path),
            fit: BoxFit.cover,
            // Decodifica no tamanho da tela, não no da foto original
            cacheWidth: (widget.size * 3).round(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => widget.placeholder,
          ),
        );
      },
    );
  }
}

// Recorte da foto (círculo ou cantos arredondados)
class PhotoFrame extends StatelessWidget {
  final double size;
  final BorderRadius? borderRadius;
  final Widget child;

  const PhotoFrame({
    super.key,
    required this.size,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: borderRadius == null
          ? ClipOval(child: child)
          : ClipRRect(borderRadius: borderRadius!, child: child),
    );
  }
}

// Foto editável no topo dos formulários: mostra a foto atual (ou a recém
// escolhida) com o botão de câmera. A alteração só é gravada quando o
// formulário é salvo (ver LocalMediaService.applyPhotoChange).
class PhotoEditor extends StatelessWidget {
  final MediaKind kind;
  final String? id; // registro existente (edição); null no cadastro
  final PhotoChange? change;
  final ValueChanged<PhotoChange> onChanged;
  final IconData icon;
  final double size;
  final bool circle;

  const PhotoEditor({
    super.key,
    required this.kind,
    required this.id,
    required this.change,
    required this.onChanged,
    required this.icon,
    this.size = 120,
    this.circle = true,
  });

  BorderRadius? get _radius =>
      circle ? null : BorderRadius.circular(size * 0.22);

  @override
  Widget build(BuildContext context) {
    final media = locator.get<LocalMediaService>();
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: _radius,
      ),
      child: Icon(icon, size: size * 0.45, color: AppColors.primary),
    );

    // Na web não há onde guardar a foto no aparelho
    if (!media.isSupported) return Center(child: placeholder);

    final photo = switch (change) {
      PhotoPicked(:final path) => PhotoFrame(
        size: size,
        borderRadius: _radius,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
        ),
      ),
      PhotoRemoved() => placeholder,
      null => LocalPhoto(
        kind: kind,
        id: id,
        size: size,
        borderRadius: _radius,
        placeholder: placeholder,
      ),
    };

    Future<void> pick() async {
      final hasPhoto =
          change is PhotoPicked ||
          (change == null &&
              id != null &&
              await media.image(kind, id!) != null);
      if (!context.mounted) return;
      final result = await showImageSourcePicker(context, canRemove: hasPhoto);
      if (result != null) onChanged(result);
    }

    return Center(
      child: Semantics(
        button: true,
        label: 'Alterar foto',
        child: GestureDetector(
          onTap: pick,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: _radius,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: photo,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.harvest,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 18,
                    color: AppColors.onHarvest,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
