import 'package:flutter/material.dart';

enum AppSnackbarType { success, warning, error }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.success,
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = _backgroundColor(context, type, colorScheme);
    final iconData = _iconFor(type);
    final fg = Colors.white;
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bgColor,
      content: Row(
        children: [
          Icon(iconData, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: duration,
      elevation: 4,
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: fg,
              onPressed: onAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Color _backgroundColor(
    BuildContext context,
    AppSnackbarType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppSnackbarType.warning:
        return Colors.amber.withAlpha(220);
      case AppSnackbarType.error:
        return Colors.redAccent.withAlpha(220);
      case AppSnackbarType.success:
        return colorScheme.primary.withAlpha(230);
    }
  }

  static IconData _iconFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackbarType.error:
        return Icons.error_outline;
      case AppSnackbarType.success:
        return Icons.check_circle_outline;
    }
  }
}
