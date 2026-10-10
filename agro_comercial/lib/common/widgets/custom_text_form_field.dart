import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Campo de texto padrão. Bordas, cores e preenchimento vêm do tema
// (inputDecorationTheme em default_theme.dart).
class CustomTextFormField extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final String? hintText;
  final String? labelText;
  final TextCapitalization? textCapitalization;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final bool? obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool enabled;

  const CustomTextFormField({
    super.key,
    this.padding,
    this.hintText,
    this.labelText,
    this.textCapitalization,
    this.controller,
    this.keyboardType,
    this.maxLength,
    this.textInputAction,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText,
    this.inputFormatters,
    this.validator,
    this.helperText,
    this.onEditingComplete,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  String? _helperText;

  @override
  void initState() {
    super.initState();
    _helperText = widget.helperText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: TextFormField(
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        // A dica some ao começar a digitar e volta se o campo for apagado
        onChanged: (value) {
          if (value.length == 1) {
            setState(() => _helperText = null);
          } else if (value.isEmpty) {
            setState(() => _helperText = widget.helperText);
          }
        },
        validator: widget.validator,
        style: AppTextStyles.inputText.copyWith(
          color: AppColors.ink,
          fontSize: 15,
        ),
        inputFormatters: widget.inputFormatters,
        obscureText: widget.obscureText ?? false,
        textInputAction: widget.textInputAction,
        onEditingComplete: widget.onEditingComplete,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        controller: widget.controller,
        textCapitalization:
            widget.textCapitalization ?? TextCapitalization.none,
        decoration: InputDecoration(
          errorMaxLines: 3,
          helperText: _helperText,
          helperMaxLines: 3,
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon == null
              ? null
              : Icon(widget.prefixIcon, size: 20),
          hintText: widget.hintText,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: widget.labelText,
        ),
      ),
    );
  }
}
