import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/services/notification_delivery_service.dart';
import 'package:real_state/features/notifications/data/services/fcm_service.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/models/entities/location_area.dart';

import 'fake_firebase.dart';

class FakeFirebaseMessaging implements FirebaseMessaging {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements fb_auth.FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFcmService extends FcmService {
  FakeFcmService()
    : super(
        FakeFirebaseMessaging(),
        FakeFirebaseFirestore(),
        FakeFirebaseAuth(),
      );

  @override
  Stream<AppNotification> get foregroundNotifications => const Stream.empty();

  @override
  Stream<AppNotification> get notificationTaps => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> attachUser(String? userId) async {}

  @override
  Future<void> detachUser() async {}

  @override
  Future<AppNotification?> initialMessage() async => null;

  @override
  Future<List<String>> fetchTokensForUsers(List<String> userIds) async =>
      const [];

  @override
  Future<NotificationDeliveryResult> sendNotificationToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, dynamic> notificationData,
  }) async {
    return const NotificationDeliveryResult(
      successCount: 0,
      failureCount: 0,
      failures: [],
    );
  }
}

class FakeLocationAreaRemoteDataSource extends LocationAreaRemoteDataSource {
  FakeLocationAreaRemoteDataSource({Map<String, LocationArea>? names})
    : _names = Map.of(names ?? const {}),
      super(FakeFirebaseFirestore());

  final Map<String, LocationArea> _names;

  @override
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) async {
    final result = <String, LocationArea>{};
    for (final id in ids) {
      final area = _names[id];
      if (area != null) result[id] = area;
    }
    return result;
  }

  @override
  Future<Map<String, LocationArea>> fetchAll() async => Map.of(_names);
}
