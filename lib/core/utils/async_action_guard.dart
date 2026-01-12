import 'package:flutter/foundation.dart';

/// Helper that prevents duplicate async actions and exposes running state.
class AsyncActionGuard extends ValueNotifier<bool> {
  AsyncActionGuard() : super(false);

  bool get isRunning => value;

  /// Runs [action] only if no other guarded action is active.
  /// Returns null if the action was skipped because another one is running.
  Future<T?> run<T>(Future<T> Function() action) async {
    if (value) return null;
    value = true;
    try {
      return await action();
    } finally {
      value = false;
    }
  }
}
