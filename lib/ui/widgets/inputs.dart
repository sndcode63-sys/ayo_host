import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Labelled text field matching the Figma input pattern:
/// small caps label above a soft-grey rounded field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.readOnly = false,
    this.maxLines = 1,
    this.onChanged,
    this.onTap,
  });

  final String? label;
  final String hint;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      onChanged: onChanged,
      onTap: onTap,
      style: AppText.input,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.input.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.fieldFill,
        prefixIcon: prefix,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!.toUpperCase(), style: AppText.fieldLabel),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}

/// Dropdown styled like [AppTextField].
class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String? label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      style: AppText.input,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 18, color: AppColors.textMuted),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.input.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );

    if (label == null) return dropdown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!.toUpperCase(), style: AppText.fieldLabel),
        const SizedBox(height: 6),
        dropdown,
      ],
    );
  }
}
