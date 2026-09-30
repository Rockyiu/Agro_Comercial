import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:flutter/material.dart';

// Mostra o carregamento POR CIMA do conteúdo, sem removê-lo da tela.
// Assim, se o salvamento falhar, o formulário continua preenchido.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) ...[
          const ModalBarrier(dismissible: false, color: Colors.black12),
          const Center(child: CustomCircularProgressIndicator()),
        ],
      ],
    );
  }
}
