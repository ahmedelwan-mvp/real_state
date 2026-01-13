import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/pages/notifications_list_view.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final RefreshController _refreshController;
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _bloc = NotificationsBloc(
      context.read<NotificationsRepository>(),
      context.read<AuthRepositoryDomain>(),
      context.read<NotificationMessagingService>(),
      context.read<PropertiesRepository>(),
      context.read<LocationAreasRepository>(),
      context.read<AcceptAccessRequestUseCase>(),
      context.read<RejectAccessRequestUseCase>(),
    );
    _bloc.loadFirstPage();
  }

  @override
  void dispose() {
    _bloc.close();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'notifications'),
        body: BaseGradientPage(
          child: BlocConsumer<NotificationsBloc, NotificationsState>(
            listener: (context, state) {
              if (state is NotificationsLoading) {
                _refreshController.resetNoData();
              }
              if (state is NotificationsDataState &&
                  state.infoMessage != null) {
                AppSnackbar.show(context, state.infoMessage!);
                context.read<NotificationsBloc>().clearInfo();
              }
              if (state is NotificationsPartialFailure ||
                  state is NotificationsActionFailure) {
                final message = state is NotificationsPartialFailure
                    ? state.message
                    : (state as NotificationsActionFailure).message;
                AppSnackbar.show(context, message, type: AppSnackbarType.error);
              }
              if (state is NotificationsDataState) {
                _refreshController.refreshCompleted();
                if (state.hasMore) {
                  _refreshController.loadComplete();
                } else {
                  _refreshController.loadNoData();
                }
              } else if (state is NotificationsFailure) {
                _refreshController.refreshFailed();
                _refreshController.loadFailed();
              }
            },
            builder: (context, state) {
              final isInitialLoading =
                  state is NotificationsInitial ||
                  state is NotificationsLoading;
              final dataState = state is NotificationsDataState ? state : null;
              final isOwner = state is NotificationsStateWithRole
                  ? state.isOwner
                  : false;
              final items = isInitialLoading
                  ? _placeholderNotifications(isOwner)
                  : dataState?.items ?? const [];
              final pendingRequests =
                  dataState?.pendingRequestIds ?? const <String>{};
              final actionStatuses =
                  dataState?.actionStatuses ??
                  const <String, NotificationActionStatus>{};
              final bloc = context.read<NotificationsBloc>();
              final currentUserId = bloc.currentUserId;
              final currentRole = bloc.currentRole;

              final listItems = items.map((notification) {
                final summary =
                    dataState?.propertySummaries[notification.propertyId];
                final viewModel = NotificationViewModel.fromNotification(
                  notification: notification,
                  propertySummary: summary,
                );
                final actionStatus =
                    actionStatuses[notification.id] ??
                    NotificationActionStatus.idle;
                final canNavigate =
                    !isInitialLoading &&
                    notification.type != AppNotificationType.general &&
                    (notification.propertyId?.isNotEmpty ?? false);
                final canAct =
                    !isInitialLoading &&
                    notification.type == AppNotificationType.accessRequest &&
                    (notification.requestId?.isNotEmpty ?? false) &&
                    (notification.requestStatus == null ||
                        notification.requestStatus ==
                            AccessRequestStatus.pending);
                final allowActions =
                    canAcceptRejectAccessRequests(currentRole) &&
                    notification.targetUserId != null &&
                    notification.targetUserId == currentUserId;
                final isActionPending =
                    canAct &&
                    pendingRequests.contains(notification.requestId ?? '');
                final isActionBusy = actionStatus.isBusy || isActionPending;

                return NotificationListItem(
                  viewModel: viewModel,
                  isOwner: isOwner,
                  isTarget: allowActions,
                  showActions: allowActions,
                  actionStatus: actionStatus,
                  onTap: canNavigate
                      ? () {
                          bloc.markRead(notification.id);
                          unawaited(
                            context.push(
                              '/property/${notification.propertyId}',
                            ),
                          );
                        }
                      : null,
                  onAccept:
                      allowActions &&
                          canAct &&
                          !isActionBusy &&
                          actionStatus == NotificationActionStatus.idle
                      ? () {
                          unawaited(
                            bloc.accept(
                              notification.id,
                              notification.requestId!,
                            ),
                          );
                        }
                      : null,
                  onReject:
                      allowActions &&
                          canAct &&
                          !isActionBusy &&
                          actionStatus == NotificationActionStatus.idle
                      ? () async {
                          final result = await AppConfirmDialog.show(
                            context,
                            titleKey: 'reject',
                            descriptionKey: 'are_you_sure',
                            confirmLabelKey: 'reject',
                            cancelLabelKey: 'cancel',
                            isDestructive: true,
                          );
                          if (result == AppConfirmResult.confirmed) {
                            unawaited(
                              bloc.reject(
                                notification.id,
                                notification.requestId!,
                              ),
                            );
                          }
                        }
                      : null,
                );
              }).toList();

              final showError = state is NotificationsFailure && items.isEmpty;
              final errorMessage = state is NotificationsFailure
                  ? state.message
                  : null;

              return NotificationListView(
                refreshController: _refreshController,
                isLoading: isInitialLoading,
                hasMore: dataState?.hasMore ?? false,
                items: listItems,
                onRefresh: _onRefresh,
                onLoadMore: () => bloc.loadMore(),
                showError: showError,
                errorMessage: errorMessage,
                onRetry: () => bloc.loadFirstPage(),
                emptyMessage: 'no_notifications_description'.tr(),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onRefresh() {
    _refreshController.resetNoData();
    context.read<NotificationsBloc>().loadFirstPage();
  }

  List<AppNotification> _placeholderNotifications(bool isOwner) {
    return List.generate(6, (i) {
      final isAccess = i.isOdd;
      return AppNotification(
        id: 'placeholder-$i',
        type: isAccess
            ? AppNotificationType.accessRequest
            : AppNotificationType.general,
        title: 'loading_notification'.tr(),
        body: 'loading_details'.tr(),
        createdAt: DateTime.now(),
        isRead: false,
        propertyId: isAccess ? 'property-$i' : null,
        requesterId: isAccess ? 'user-$i' : null,
        requestId: isAccess ? 'request-$i' : null,
        requestType: isAccess ? AccessRequestType.images : null,
        requestStatus: isAccess && isOwner ? AccessRequestStatus.pending : null,
      );
    });
  }
}
