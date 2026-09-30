import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

// Campos de horímetro inicial/final das máquinas motorizadas
class HorimeterFields extends StatelessWidget {
  final TextEditingController initialController;
  final TextEditingController finalController;

  const HorimeterFields({
    super.key,
    required this.initialController,
    required this.finalController,
  });

  @override
  Widget build(BuildContext context) {
    const keyboard = TextInputType.numberWithOptions(decimal: true);
    return Row(
      children: [
        Expanded(
          child: CustomTextFormField(
            controller: initialController,
            labelText: "HORÍMETRO INICIAL",
            keyboardType: keyboard,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextFormField(
            controller: finalController,
            labelText: "HORÍMETRO FINAL",
            keyboardType: keyboard,
          ),
        ),
      ],
    );
  }
}

// Leitura validada dos campos de horímetro
class HorimeterReading {
  final double initial;
  final double end;

  const HorimeterReading(this.initial, this.end);

  // Devolve a leitura ou a mensagem de erro para mostrar ao usuário.
  // [expectedInitial]: no cadastro, o horímetro inicial precisa bater com o
  // horímetro atual da máquina no sistema (bloqueio rigoroso).
  static ({HorimeterReading? reading, String? error}) parse({
    required TextEditingController initialController,
    required TextEditingController finalController,
    int? expectedInitial,
  }) {
    final initial = Parsers.decimal(initialController.text);
    final end = Parsers.decimal(finalController.text);

    if (initial == null || end == null) {
      return (reading: null, error: "Preencha o horímetro inicial e final!");
    }
    if (expectedInitial != null && initial.toInt() != expectedInitial) {
      return (
        reading: null,
        error:
            "Atenção: Horímetro inicial ($initial) não confere com o sistema (${expectedInitial}h).",
      );
    }
    if (end < initial) {
      return (
        reading: null,
        error: "Horímetro final deve ser maior que o inicial!",
      );
    }
    return (reading: HorimeterReading(initial, end), error: null);
  }
}
