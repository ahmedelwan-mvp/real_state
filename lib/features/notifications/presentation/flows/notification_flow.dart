import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/usecases/handle_foreground_notification_usecase.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/dialogs/access_request_dialog.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';

class NotificationFlow {
  NotificationFlow({
    required NotificationsBloc bloc,
    required HandleForegroundNotificationUseCase backgroundUseCase,
  }) : _bloc = bloc,
       _useCase = backgroundUseCase;

  final NotificationsBloc _bloc;
  final HandleForegroundNotificationUseCase _useCase;

  bool _configured = false;
  StreamSubscription<AppNotification>? _tapSub;
  StreamSubscription<AppNotification>? _fgSub;
  StreamSubscription? _authSub;
  late BuildContext _context;
  late GoRouter _router;
  UserRole? _currentRole;
  String? _currentUserId;
  AppNotification? _pendingTappedNotification;
  String? _lastSnackbarNotificationId;
  DateTime? _lastSnackbarAt;
  String? _activeDialogRequestId;

  Future<void> configure({
    required BuildContext context,
    required GoRouter router,
  }) async {
    if (_configured) return;
    _configured = true;
    _context = context;
    _router = router;

    final messaging = context.read<NotificationMessagingService>();
    final auth = context.read<AuthRepositoryDomain>();

    await messaging.initialize();

    _authSub = auth.userChanges.listen((user) {
      messaging.attachUser(user?.id);
      _currentRole = user?.role;
      _currentUserId = user?.id;
    });

    _tapSub = messaging.notificationTaps.listen((notification) async {
      _pendingTappedNotification = notification;
      await _handleTappedNotification(notification);
      _bloc.markRead(notification.id);
    });

    _fgSub = messaging.foregroundNotifications.listen((notification) async {
      await _handleForegroundNotification(notification);
    });

    final initial = await messaging.initialMessage();
    if (initial != null) {
      _pendingTappedNotification = initial;
      await _handleTappedNotification(initial);
      _bloc.markRead(initial.id);
    }
  }

  void dispose() {
    _authSub?.cancel();
    _tapSub?.cancel();
    _fgSub?.cancel();
  }

  Future<void> _handleTappedNotification(AppNotification notification) async {
    final intent = await _useCase.call(
      notification: notification,
      currentRole: _currentRole,
      currentUserId: _currentUserId,
      pendingTappedNotification: _pendingTappedNotification,
    );
    if (intent.collectorAccessDenied) {
      AppSnackbar.show(
        _context,
        'access_denied'.tr(),
        type: AppSnackbarType.error,
      );
      return;
    }
    _handleNavigation(notification);
    if (intent.showDialog && intent.dialogPayload != null) {
      await _showAccessRequestDialog(notification, intent.dialogPayload!);
      _pendingTappedNotification = null;
    }
  }

  Future<void> _handleForegroundNotification(
    AppNotification notification,
  ) async {
    final intent = await _useCase.call(
      notification: notification,
      currentRole: _currentRole,
      currentUserId: _currentUserId,
      pendingTappedNotification: _pendingTappedNotification,
    );
    if (intent.showDialog && intent.dialogPayload != null) {
      await _showAccessRequestDialog(notification, intent.dialogPayload!);
      _pendingTappedNotification = null;
      return;
    }
    if (!_shouldShowForegroundSnackbar(notification)) return;
    final message = notification.body.isNotEmpty
        ? notification.body
        : notification.title;
    AppSnackbar.show(_context, message);
  }

  void _handleNavigation(AppNotification notification) {
    if (notification.type == AppNotificationType.general) return;
    final propertyId = notification.propertyId;
    if (propertyId == null || propertyId.isEmpty) return;
    _router.push('/property/$propertyId');
  }

  bool _shouldShowForegroundSnackbar(AppNotification notification) {
    final now = DateTime.now();
    if (_lastSnackbarNotificationId == notification.id &&
        _lastSnackbarAt != null &&
        now.difference(_lastSnackbarAt!) < const Duration(seconds: 5)) {
      return false;
    }
    _lastSnackbarNotificationId = notification.id;
    _lastSnackbarAt = now;
    return true;
  }

  Future<void> _showAccessRequestDialog(
    AppNotification notification,
    NotificationRequestDialogPayload payload,
  ) async {
    final requestId = notification.requestId;
    if (requestId == null) return;
    if (_activeDialogRequestId == requestId) return;
    _activeDialogRequestId = requestId;
    final dialogContext =
        _router.routerDelegate.navigatorKey.currentContext ?? _context;

    await showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: _bloc,
        child: AccessRequestDialog(
          notification: notification,
          propertySummary: payload.summary,
          requesterName: payload.requesterName,
          onCompleted: _refreshNotificationsIfAvailable,
        ),
      ),
    );

    _activeDialogRequestId = null;
  }

  void _refreshNotificationsIfAvailable() {
    try {
      _bloc.loadFirstPage();
    } catch (_) {}
  }
}
