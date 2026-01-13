import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/utils/time_ago.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/domain/models/notification_property_summary.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card_actions.dart';

class NotificationCardView extends StatelessWidget {
  const NotificationCardView({
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

  bool get _isBusy => actionStatus != NotificationActionStatus.idle;

  bool get _showInlineLoader =>
      actionStatus == NotificationActionStatus.accepting ||
      actionStatus == NotificationActionStatus.rejecting;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Card(
      key: ValueKey('notification_card_${viewModel.notification.id}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  decoration: BoxDecoration(
                    color: viewModel.isUnread
                        ? accentColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (viewModel.notification.type) {
      case AppNotificationType.accessRequest:
        return _buildAccessRequest(context);
      case AppNotificationType.propertyAdded:
        return _buildPropertyAdded(context);
      case AppNotificationType.general:
        return _buildGeneral(context);
    }
  }

  Widget _buildAccessRequest(BuildContext context) {
    final notification = viewModel.notification;
    final status = notification.requestStatus ?? AccessRequestStatus.pending;
    final summary = viewModel.propertySummary;
    final title = notification.title.isNotEmpty
        ? notification.title
        : 'access_request_title'.tr();
    final subtitle = _propertySubtitle(context, summary);
    final typeLabel = _requestTypeLabel();
    final icon = _requestTypeIcon();
    final price = _priceText(summary);
    final timeLabel = timeAgo(notification.createdAt);
    final showActionButtons =
        status == AccessRequestStatus.pending &&
        isOwner &&
        isTarget &&
        showActions;
    final isActionDisabled = _isBusy;
    final rejectLoading = actionStatus == NotificationActionStatus.rejecting;
    final acceptLoading = actionStatus == NotificationActionStatus.accepting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LeadingImage(summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(context, title),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (price.isNotEmpty)
                    Text(
                      price,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusBadge(status.name, context),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _TypeIcon(icon: icon),
            const SizedBox(width: 8),
            Text(
              typeLabel,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (notification.requesterName != null &&
            notification.requesterName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'access_request_requester'.tr(args: [notification.requesterName!]),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (notification.requestMessage != null &&
            notification.requestMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            notification.requestMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 12),
        NotificationCardActions(
          notificationId: notification.id,
          showActionButtons: showActionButtons,
          isActionDisabled: isActionDisabled,
          showInlineLoader: _showInlineLoader,
          acceptLoading: acceptLoading,
          rejectLoading: rejectLoading,
          onAccept: onAccept,
          onReject: onReject,
        ),
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyAdded(BuildContext context) {
    final notification = viewModel.notification;
    final summary = viewModel.propertySummary;
    final fallbackTitle = notification.title == notification.propertyId
        ? null
        : notification.title;
    final title = _propertyTitle(context, summary, fallback: fallbackTitle);
    final subtitle = _propertySubtitle(context, summary);
    final timeLabel = timeAgo(notification.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingImage(summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleRow(context, title),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (_priceText(summary).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_priceText(summary)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          timeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (viewModel.notification.body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(viewModel.notification.body),
        ],
      ],
    );
  }

  Widget _buildGeneral(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _TypeIcon(icon: Icons.notifications_none),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTitleRow(context, viewModel.notification.title),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (viewModel.notification.body.isNotEmpty)
          Text(viewModel.notification.body),
        Text(
          timeAgo(viewModel.notification.createdAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context, String title) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (viewModel.isUnread) ...[
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color color;
    switch (status) {
      case 'accepted':
        color = colors.primary;
        break;
      case 'rejected':
        color = colors.error;
        break;
      case 'expired':
        color = colors.outline;
        break;
      default:
        color = colors.secondary;
    }
    final label = 'access_request_status_$status'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _propertyTitle(
    BuildContext context,
    NotificationPropertySummary? summary, {
    String? fallback,
  }) {
    if (summary == null) return fallback ?? 'property_unavailable'.tr();
    if (summary.isMissing) return 'property_unavailable'.tr();
    if (summary.title.trim().isEmpty) return 'untitled'.tr();
    return summary.title;
  }

  String _propertySubtitle(
    BuildContext context,
    NotificationPropertySummary? summary,
  ) {
    if (summary == null || summary.isMissing) return '';
    final parts = <String>[];
    if (summary.purposeKey != null) {
      parts.add(summary.purposeKey!.tr());
    }
    if (summary.areaName != null && summary.areaName!.isNotEmpty) {
      parts.add(summary.areaName!);
    }
    return parts.join(' • ');
  }

  String _priceText(NotificationPropertySummary? summary) {
    if (summary == null || summary.isMissing) return '';
    if (summary.price == null) return '';
    return PriceFormatter.format(summary.price!, currency: 'AED');
  }

  String _requestTypeLabel() {
    switch (viewModel.notification.requestType) {
      case AccessRequestType.phone:
        return 'request_view_phone'.tr();
      case AccessRequestType.images:
        return 'request_view_images'.tr();
      default:
        return 'request_view_location'.tr();
    }
  }

  IconData _requestTypeIcon() {
    switch (viewModel.notification.requestType) {
      case AccessRequestType.phone:
        return Icons.phone_in_talk_outlined;
      case AccessRequestType.images:
        return Icons.photo_library_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}

class _TypeIcon extends StatelessWidget {
  final IconData icon;
  const _TypeIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(76),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: scheme.primary),
    );
  }
}

class _LeadingImage extends StatelessWidget {
  final NotificationPropertySummary? summary;

  const _LeadingImage(this.summary);

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.home_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    final url = summary?.coverImageUrl;
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
