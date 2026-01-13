import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/entities/notifications_page.dart'
    as notifications_model;
import 'package:real_state/features/notifications/presentation/pages/notifications_page.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart'
    show PageResult;
import 'package:shared_preferences/shared_preferences.dart';

import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_test_app.dart';
import '../fake_auth_repo/fake_auth_repo.dart';

class _FakeAccessRepo implements AccessRequestsRepository {
  List<AccessRequest> _items = [];

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async {
    return PageResult(items: _items, lastDocument: null, hasMore: false);
  }

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async {
    final idx = _items.indexWhere((i) => i.id == requestId);
    if (idx >= 0) {
      final old = _items[idx];
      final updated = AccessRequest(
        id: old.id,
        propertyId: old.propertyId,
        requesterId: old.requesterId,
        type: old.type,
        message: old.message,
        status: status,
        createdAt: old.createdAt,
        expiresAt: old.expiresAt,
        decidedAt: DateTime.now(),
        decidedBy: decidedBy,
      );
      _items[idx] = updated;
      return updated;
    }
    throw Exception('not found');
  }

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    for (final item in _items) {
      if (item.propertyId == propertyId &&
          item.requesterId == requesterId &&
          item.type == type &&
          item.status == AccessRequestStatus.accepted) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<AccessRequest?> fetchById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    return const Stream.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('owner sees pending requests and can accept', (tester) async {
    final fakeRepo = _FakeAccessRepo();
    final now = DateTime.now();
    fakeRepo._items = [
      AccessRequest(
        id: 'r1',
        propertyId: 'p1',
        requesterId: 'u2',
        type: AccessRequestType.images,
        message: 'please',
        status: AccessRequestStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    ];

    final fakeNotifications = FakeNotificationsRepository(
      initialPages: [
        notifications_model.NotificationsPage(
          items: [
            AppNotification(
              id: 'n1',
              type: AppNotificationType.accessRequest,
              title: 'access_request_title',
              body: 'Message: please',
              createdAt: now,
              isRead: false,
              requesterName: 'u2',
              requestId: 'r1',
              requestStatus: AccessRequestStatus.pending,
              requestType: AccessRequestType.images,
              targetUserId: 'owner1',
              propertyId: 'p1',
              requestMessage: 'Message: please',
            ),
          ],
          lastDocument: null,
          hasMore: false,
        ),
      ],
    );

    final fakeAuth = FakeAuthRepo(
      const UserEntity(id: 'owner1', email: 'o@x', role: UserRole.owner),
    );

    await pumpTestApp(
      tester,
      const NotificationsPage(),
      dependencies: TestAppDependencies(
        authRepositoryOverride: fakeAuth,
        accessRequestsRepositoryOverride: fakeRepo,
        notificationsRepositoryOverride: fakeNotifications,
      ),
    );

    final cardFinder = byKeyStr('notification_card_n1');
    await pumpUntilFound(tester, cardFinder);
    expect(cardFinder, findsOneWidget);
    final acceptFinder = byKeyStr('notification_accept_n1');
    final rejectFinder = byKeyStr('notification_reject_n1');
    expect(acceptFinder, findsOneWidget);
    expect(rejectFinder, findsOneWidget);

    await tester.tap(acceptFinder);
    await tester.pump(const Duration(milliseconds: 200));

    for (var i = 0; i < 15 && tester.any(acceptFinder); i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    expect(acceptFinder, findsNothing);
    expect(rejectFinder, findsNothing);
  });
}
