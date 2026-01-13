enum NotificationActionStatus { idle, accepting, rejecting }

extension NotificationActionStatusX on NotificationActionStatus {
  bool get isBusy => this != NotificationActionStatus.idle;

  bool get isInlineLoader =>
      this == NotificationActionStatus.accepting ||
      this == NotificationActionStatus.rejecting;
}
