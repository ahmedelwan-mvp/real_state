/// Aggregated result from a notification delivery attempt.
class NotificationDeliveryResult {
  final int successCount;
  final int failureCount;
  final List<NotificationDeliveryFailure> failures;

  const NotificationDeliveryResult({
    required this.successCount,
    required this.failureCount,
    required this.failures,
  });
}

/// Details for a single failed token delivery.
class NotificationDeliveryFailure {
  final String token;
  final String error;

  const NotificationDeliveryFailure({required this.token, required this.error});
}

/// Abstraction used by the domain layer to interact with Firebase Messaging/Functions.
abstract class NotificationDeliveryService {
  Future<List<String>> fetchTokensForUsers(List<String> userIds);

  Future<NotificationDeliveryResult> sendNotificationToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, dynamic> notificationData,
  });
}
