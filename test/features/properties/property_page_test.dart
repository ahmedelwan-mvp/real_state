import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/pages/property_page.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

import '../fake_auth_repo/fake_auth_repo.dart';
import '../../fakes/fake_firebase.dart';
import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_test_app.dart';

class _FakePropertiesRepo extends PropertiesRepositoryImpl {
  final Property _prop;

  _FakePropertiesRepo(this._prop) : super(FakeFirebaseFirestore());

  @override
  Future<Property?> getById(String id) async => _prop;
}

class _FakeAccessRepo implements AccessRequestsRepository {
  _FakeAccessRepo();

  bool called = false;
  AccessRequestType? lastType;

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    called = true;
    lastType = type;
    return AccessRequest(
      id: 'r1',
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      message: message,
      status: AccessRequestStatus.accepted,
      createdAt: DateTime.now(),
      ownerId: targetUserId,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    return const Stream.empty();
  }

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async => PageResult(items: const [], lastDocument: null, hasMore: false);

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async => null;

  @override
  Future<AccessRequest?> fetchById(String id) async => null;

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async => throw UnimplementedError();
}

class _StreamAccessRepo implements AccessRequestsRepository {
  _StreamAccessRepo();

  final StreamController<AccessRequest?> ctrl = StreamController.broadcast();
  bool called = false;

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    called = true;
    final now = DateTime.now();
    final request = AccessRequest(
      id: 'r1',
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      message: message,
      status: AccessRequestStatus.pending,
      createdAt: now,
      ownerId: targetUserId,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    ctrl.add(request);
    return request;
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    return ctrl.stream;
  }

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async => PageResult(items: const [], lastDocument: null, hasMore: false);

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async => null;

  @override
  Future<AccessRequest?> fetchById(String id) async => null;

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async => throw UnimplementedError();
}

void main() {
  testWidgets('shows locked images and allows requesting images access', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: true,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: 'u1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _FakeAccessRepo();
    final fakeNotifications = FakeNotificationsRepository();
    final fakeUsers = FakeUsersRepository();
    fakeUsers.seed(
      ManagedUser(id: 'u1', email: 'u@x', role: UserRole.collector),
    );
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: fakeProps,
      accessRequestsRepositoryOverride: fakeAccess,
      notificationsRepositoryOverride: fakeNotifications,
      usersRepositoryOverride: fakeUsers,
      authRepositoryOverride: FakeAuthRepo(
        UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    await pumpTestApp(tester, PropertyPage(id: 'p1'), dependencies: deps);

    await tester.pumpAndSettle();

    expect(find.text('Images are hidden for this property'), findsOneWidget);

    await tester.tap(find.text('Request Images Access'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Please');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(fakeAccess.called, isTrue);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('shows images after owner accepts later via stream', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: true,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: 'u1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _StreamAccessRepo();
    final fakeNotifications = FakeNotificationsRepository();
    final fakeUsers = FakeUsersRepository();
    fakeUsers.seed(
      ManagedUser(id: 'u1', email: 'u@x', role: UserRole.collector),
    );
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: fakeProps,
      accessRequestsRepositoryOverride: fakeAccess,
      notificationsRepositoryOverride: fakeNotifications,
      usersRepositoryOverride: fakeUsers,
      authRepositoryOverride: FakeAuthRepo(
        UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    await pumpTestApp(tester, PropertyPage(id: 'p1'), dependencies: deps);

    await tester.pumpAndSettle();

    expect(find.text('Images are hidden for this property'), findsOneWidget);

    await tester.tap(find.text('Request Images Access'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(fakeAccess.called, isTrue);

    final now = DateTime.now();
    fakeAccess.ctrl.add(
      AccessRequest(
        id: 'r1',
        propertyId: 'p1',
        requesterId: 'u1',
        type: AccessRequestType.images,
        message: null,
        status: AccessRequestStatus.accepted,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Images access accepted'), findsOneWidget);
  });

  testWidgets('shows phone after owner accepts later via stream', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: const [],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: false,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: 'u1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _StreamAccessRepo();
    final fakeNotifications = FakeNotificationsRepository();
    final fakeUsers = FakeUsersRepository();
    fakeUsers.seed(
      ManagedUser(id: 'u1', email: 'u@x', role: UserRole.collector),
    );
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: fakeProps,
      accessRequestsRepositoryOverride: fakeAccess,
      notificationsRepositoryOverride: fakeNotifications,
      usersRepositoryOverride: fakeUsers,
      authRepositoryOverride: FakeAuthRepo(
        UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    await pumpTestApp(tester, PropertyPage(id: 'p1'), dependencies: deps);

    await tester.pumpAndSettle();

    expect(find.text('Phone is hidden'), findsOneWidget);

    await tester.tap(find.text('Request Owner Phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    fakeAccess.ctrl.add(
      AccessRequest(
        id: 'r2',
        propertyId: 'p1',
        requesterId: 'u1',
        type: AccessRequestType.phone,
        message: null,
        status: AccessRequestStatus.accepted,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('123456'), findsOneWidget);
    expect(find.text('Phone access accepted'), findsOneWidget);
  });
}
