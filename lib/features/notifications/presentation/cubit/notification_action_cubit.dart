import 'package:bloc/bloc.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';

import 'notification_action_state.dart';

class NotificationActionCubit extends Cubit<NotificationActionState> {
  NotificationActionCubit(this._notificationsBloc)
      : super(const NotificationActionState());

  final NotificationsBloc _notificationsBloc;

  NotificationActionStatus statusFor(String notificationId) =>
      state.statusFor(notificationId);

  Future<void> accept({
    required String notificationId,
    required String requestId,
  }) {
    return _runGuarded(
      notificationId,
      NotificationActionStatus.accepting,
      () => _notificationsBloc.accept(notificationId, requestId),
    );
  }

  Future<void> reject({
    required String notificationId,
    required String requestId,
  }) {
    return _runGuarded(
      notificationId,
      NotificationActionStatus.rejecting,
      () => _notificationsBloc.reject(notificationId, requestId),
    );
  }

  Future<void> open({
    required String notificationId,
    required Future<void> Function() action,
  }) {
    return _runGuarded(
      notificationId,
      NotificationActionStatus.opening,
      action,
    );
  }

  Future<void> _runGuarded(
    String notificationId,
    NotificationActionStatus status,
    Future<void> Function() action,
  ) async {
    if (state.statusFor(notificationId) != NotificationActionStatus.idle) {
      return;
    }
    emit(state.withStatus(notificationId, status));
    try {
      await action();
    } finally {
      emit(state.withStatus(notificationId, NotificationActionStatus.idle));
    }
  }
}
