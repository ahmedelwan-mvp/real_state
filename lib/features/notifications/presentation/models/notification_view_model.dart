import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/models/notification_property_summary.dart';

class NotificationViewModel {
  const NotificationViewModel({
    required this.notification,
    this.propertySummary,
    required this.isRead,
  });

  final AppNotification notification;
  final NotificationPropertySummary? propertySummary;
  final bool isRead;

  bool get isUnread => !isRead;

  factory NotificationViewModel.fromNotification({
    required AppNotification notification,
    NotificationPropertySummary? propertySummary,
  }) {
    return NotificationViewModel(
      notification: notification,
      propertySummary: propertySummary,
      isRead: notification.isRead,
    );
  }
}
