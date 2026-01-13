import 'package:flutter/material.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card_view.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.viewModel,
    required this.isOwner,
    required this.isTarget,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = true,
    this.actionStatus = NotificationActionStatus.idle,
  });

  final NotificationViewModel viewModel;
  final bool isOwner;
  final bool isTarget;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;
  final NotificationActionStatus actionStatus;

  @override
  Widget build(BuildContext context) {
    return NotificationCardView(
      viewModel: viewModel,
      isOwner: isOwner,
      isTarget: isTarget,
      onTap: onTap,
      onAccept: onAccept,
      onReject: onReject,
      showActions: showActions,
      actionStatus: actionStatus,
    );
  }
}
