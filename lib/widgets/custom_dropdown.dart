import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final String labelText;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final IconData? prefixIcon;
  final double bottomSpace;

  const CustomDropdown({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
    this.validator,
    this.prefixIcon,
    this.bottomSpace = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            labelText: labelText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            // app_theme.dart එකෙන් Theme Border එක Auto Apply වේ.
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabelBuilder(item)),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
        ),
        SizedBox(height: bottomSpace),
      ],
    );
  }
}
