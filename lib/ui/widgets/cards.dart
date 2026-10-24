import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// White card with hairline border and a layered, low-opacity shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.color = AppColors.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: card,
    );
  }
}

/// Section heading with optional trailing action, e.g. "My Cars  Manage ›".
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onTrailingTap,
    this.trailingColor,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppText.sectionTitle),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: AppText.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: trailingColor ?? AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Small status pill: "On Trip", "Available", "Uploaded", "Verified"...
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.kind});

  final String label;
  final StatusKind kind;

  factory StatusPill.auto(String status, {Key? key}) {
    switch (status) {
      case 'On Trip':
      case 'Required':
      case 'Danger':
      case 'REJECTED':
        return StatusPill(
            key: key, label: status, kind: StatusKind.danger);
      case 'Available':
      case 'Uploaded':
      case 'Active':
      case 'ACTIVE':
      case 'Verified':
        return StatusPill(
            key: key, label: status, kind: StatusKind.success);
      case 'PENDING_REVIEW':
        return StatusPill(
            key: key, label: 'Pending Review', kind: StatusKind.neutral);
      case 'DRAFT':
        return StatusPill(
            key: key, label: 'Draft', kind: StatusKind.neutral);
      default:
        return StatusPill(
            key: key, label: status, kind: StatusKind.neutral);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      StatusKind.danger => (AppColors.primarySoft, AppColors.primary),
      StatusKind.success => (AppColors.successSoft, AppColors.success),
      StatusKind.neutral => (AppColors.fieldMuted, AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusKind { danger, success, neutral }

/// Selectable chip (Electric / Sedan / SUV ...). Red outline when selected.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.chip);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        width: expanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: radius,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.fieldBorder,
          ),
        ),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style red toggle row.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
      activeThumbColor: Colors.white,
    );
  }
}
