import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Simple placeholder for tabs not covered by the current design round.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.screenTitle),
            const SizedBox(height: 8),
            Text('Coming soon', style: AppText.body),
          ],
        ),
      ),
    );
  }
}
