import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String message;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: BamcColors.background.withAlpha(200),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: BamcColors.surface,
                  border: Border.all(color: BamcColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        color: BamcColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
