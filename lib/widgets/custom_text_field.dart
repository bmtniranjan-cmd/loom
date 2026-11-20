import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final double bottomSpace;
  final int? maxLength;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.icon,
    this.isPassword = false,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.bottomSpace = 10.0,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword || obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          inputFormatters: maxLength != null
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ]
              : null,
          decoration: InputDecoration(
            labelText: label,
            counterText: "",
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: suffixIcon,
          ),
        ),
        SizedBox(height: bottomSpace),
      ],
    );
  }
}
