import 'dart:developer';

import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

class PasswordFormField extends StatefulWidget {
  final TextEditingController? controller;
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final String? labelText;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final VoidCallback? onEditingComplete; // Propriedade adicionada
  final TextInputAction?
  textInputAction; // Propriedade adicionada para o teclado

  const PasswordFormField({
    super.key, // Sintaxe moderna já aplicada
    this.controller,
    this.padding,
    this.hintText,
    this.labelText,
    this.validator,
    this.helperText,
    this.onEditingComplete,
    this.textInputAction,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    return CustomTextFormField(
      helperText: widget.helperText,
      validator: widget.validator,
      obscureText: isHidden,
      controller: widget.controller,
      padding: widget.padding,
      hintText: widget.hintText,
      labelText: widget.labelText,
      // Repassando as novas propriedades para o CustomTextFormField
      onEditingComplete: widget.onEditingComplete,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      suffixIcon: InkWell(
        borderRadius: BorderRadius.circular(23.0),
        child: Icon(isHidden ? Icons.visibility : Icons.visibility_off),
        onTap: () {
          log("Visibilidade da senha alterada");
          setState(() {
            isHidden = !isHidden;
          });
        },
      ),
    );
  }
}
