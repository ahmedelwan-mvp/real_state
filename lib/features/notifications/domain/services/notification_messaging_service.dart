import '../entities/app_notification.dart';

/// Presentation-facing contract for foreground and tap notification events.
abstract class NotificationMessagingService {
  Stream<AppNotification> get foregroundNotifications;
  Stream<AppNotification> get notificationTaps;
  Future<void> initialize();
  Future<void> attachUser(String? userId);
  Future<void> detachUser();
  Future<AppNotification?> initialMessage();
}
