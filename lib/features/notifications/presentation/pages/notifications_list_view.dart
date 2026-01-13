import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card.dart';

class NotificationListView extends StatelessWidget {
  const NotificationListView({
    super.key,
    required this.refreshController,
    required this.items,
    required this.isLoading,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.showError,
    required this.onRetry,
    required this.emptyMessage,
    this.errorMessage,
  });

  final RefreshController refreshController;
  final List<NotificationListItem> items;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final bool showError;
  final VoidCallback onRetry;
  final String emptyMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (showError && items.isEmpty) {
      return AppErrorView(
        message: errorMessage ?? 'generic_error'.tr(),
        onRetry: onRetry,
      );
    }
    if (!isLoading && items.isEmpty) {
      return EmptyStateWidget(description: emptyMessage, action: onRetry);
    }
    return SmartRefresher(
      controller: refreshController,
      enablePullUp: hasMore,
      onRefresh: onRefresh,
      onLoading: onLoadMore,
      child: AppSkeletonizer(
        enabled: isLoading,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return NotificationCard(
              viewModel: item.viewModel,
              isOwner: item.isOwner,
              isTarget: item.isTarget,
              onTap: item.onTap,
              onAccept: item.onAccept,
              onReject: item.onReject,
              showActions: item.showActions,
              actionStatus: item.actionStatus,
            );
          },
        ),
      ),
    );
  }
}

class NotificationListItem {
  const NotificationListItem({
    required this.viewModel,
    required this.isOwner,
    required this.isTarget,
    required this.showActions,
    required this.actionStatus,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  final NotificationViewModel viewModel;
  final bool isOwner;
  final bool isTarget;
  final bool showActions;
  final NotificationActionStatus actionStatus;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
}
