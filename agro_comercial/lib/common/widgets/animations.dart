import 'package:flutter/material.dart';

// Entrada suave (esmaecer + subir um pouco). Em listas, [index] escalona as
// entradas: cada item aparece um pouco depois do anterior.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.offsetY = 18,
  });

  // Atraso entre um item e o próximo (limitado, para listas longas não
  // demorarem a aparecer)
  static const _stagger = Duration(milliseconds: 55);
  static const _maxStaggered = 10;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final Duration _delay =
      widget.delay +
      FadeSlideIn._stagger *
          widget.index.clamp(0, FadeSlideIn._maxStaggered).toInt();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration + _delay,
  )..forward();

  // O atraso é o começo "parado" da animação (sem Timer)
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _delay.inMicroseconds / (widget.duration + _delay).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _progress.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _progress.value)),
          child: child,
        ),
      ),
    );
  }
}

// Encolhe levemente ao ser tocado, como um botão físico. Não captura o
// toque: o InkWell/GestureDetector de dentro continua funcionando.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.enabled && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
