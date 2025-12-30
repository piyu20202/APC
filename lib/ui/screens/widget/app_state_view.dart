import 'package:flutter/material.dart';

enum AppViewState { loading, error, empty, content }

/// Standardized UI for common page states: loading / error / empty.
///
/// Designed to be used inside `SliverFillRemaining` or any other container.
class AppStateView extends StatelessWidget {
  final AppViewState state;

  /// Main title (e.g. "Something went wrong")
  final String? title;

  /// Supporting message (e.g. error text / empty explanation)
  final String? message;

  /// Icon shown for error/empty states.
  final IconData? icon;

  /// Primary action button (e.g. Retry / View products)
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  /// Secondary action button (optional)
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// Whether to show a "Pull down to refresh" hint.
  final bool showPullToRefreshHint;

  /// Content widget for `content` state.
  final Widget? child;

  const AppStateView({
    super.key,
    required this.state,
    this.title,
    this.message,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.showPullToRefreshHint = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppViewState.loading:
        return const Center(child: CircularProgressIndicator());

      case AppViewState.content:
        return child ?? const SizedBox.shrink();

      case AppViewState.error:
      case AppViewState.empty:
        final isError = state == AppViewState.error;
        final colorScheme = Theme.of(context).colorScheme;
        final resolvedIcon =
            icon ?? (isError ? Icons.error_outline : Icons.inbox_outlined);
        final resolvedTitle =
            title ?? (isError ? 'Something went wrong' : 'Nothing to show');
        final resolvedMessage = message ??
            (isError
                ? 'Please try again.'
                : 'No data is available right now.');

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(resolvedIcon, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 14),
                  Text(
                    resolvedTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resolvedMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  if (onPrimaryAction != null && (primaryActionLabel?.isNotEmpty ?? false))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(primaryActionLabel!),
                      ),
                    ),
                  if (onSecondaryAction != null &&
                      (secondaryActionLabel?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondaryAction,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(secondaryActionLabel!),
                      ),
                    ),
                  ],
                  if (showPullToRefreshHint) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Tip: pull down to refresh.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
    }
  }
}


