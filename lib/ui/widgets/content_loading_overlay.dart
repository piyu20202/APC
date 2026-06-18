import 'package:flutter/material.dart';

/// Semi-transparent overlay with loader — blocks interaction until content loads.
class ContentLoadingOverlay extends StatelessWidget {
  const ContentLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFC107),
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }
}
