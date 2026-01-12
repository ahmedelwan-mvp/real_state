import 'package:equatable/equatable.dart';

/// Tracks the current busy status of notification actions.
enum NotificationActionStatus {
  idle,
  accepting,
  rejecting,
  opening,
}

class NotificationActionState extends Equatable {
  final Map<String, NotificationActionStatus> _statuses;

  const NotificationActionState([Map<String, NotificationActionStatus>? statuses])
      : _statuses = statuses ?? const {};

  NotificationActionStatus statusFor(String notificationId) =>
      _statuses[notificationId] ?? NotificationActionStatus.idle;

  NotificationActionState withStatus(
    String notificationId,
    NotificationActionStatus status,
  ) {
    final updated = Map<String, NotificationActionStatus>.from(_statuses);
    if (status == NotificationActionStatus.idle) {
      updated.remove(notificationId);
    } else {
      updated[notificationId] = status;
    }
    return NotificationActionState(Map.unmodifiable(updated));
  }

  @override
  List<Object?> get props => [Map.unmodifiable(_statuses)];
}
