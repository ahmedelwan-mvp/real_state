import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/models/notification_property_summary.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/users/domain/repositories/users_lookup_repository.dart';

class HandleForegroundNotificationUseCase {
  HandleForegroundNotificationUseCase(
    this._propertiesRepository,
    this._locations,
    this._usersRepository,
  );

  final PropertiesRepository _propertiesRepository;
  final LocationAreasRepository _locations;
  final UsersLookupRepository _usersRepository;

  final Map<String, NotificationPropertySummary> _propertyCache = {};
  final Map<String, String> _requesterCache = {};
  final Map<String, String> _areaCache = {};

  Future<ForegroundNotificationIntent> call({
    required AppNotification notification,
    required UserRole? currentRole,
    required String? currentUserId,
    required AppNotification? pendingTappedNotification,
  }) async {
    if (!_isAccessRequest(notification)) {
      return const ForegroundNotificationIntent();
    }

    final canShowDialog = _canShowAccessRequestDialog(
      notification,
      currentRole,
      currentUserId,
      pendingTappedNotification,
    );
    if (!canShowDialog) {
      return const ForegroundNotificationIntent();
    }

    if (currentRole == UserRole.collector &&
        !await _collectorCanOpenAccessRequest(notification)) {
      return const ForegroundNotificationIntent(collectorAccessDenied: true);
    }

    final payload = await _buildDialogPayload(notification);
    return ForegroundNotificationIntent(
      showDialog: payload != null,
      dialogPayload: payload,
    );
  }

  Future<NotificationRequestDialogPayload?> _buildDialogPayload(
    AppNotification notification,
  ) async {
    final propertySummary = await _loadPropertySummary(notification);
    if (propertySummary == null) return null;
    final requesterName = await _resolveRequesterName(notification);
    return NotificationRequestDialogPayload(
      summary: propertySummary,
      requesterName: requesterName,
    );
  }

  Future<NotificationPropertySummary?> _loadPropertySummary(
    AppNotification notification,
  ) async {
    final propertyId = notification.propertyId;
    if (propertyId == null || propertyId.isEmpty) {
      return const NotificationPropertySummary(
        title: 'property_unavailable',
        isMissing: true,
      );
    }

    if (_propertyCache.containsKey(propertyId)) {
      return _propertyCache[propertyId];
    }

    Property? property;
    try {
      property = await _propertiesRepository.getById(propertyId);
    } catch (_) {
      property = null;
    }

    if (property == null) {
      final missing = const NotificationPropertySummary(
        title: 'property_unavailable',
        isMissing: true,
      );
      _propertyCache[propertyId] = missing;
      return missing;
    }

    String? areaName;
    final areaId = property.locationAreaId;
    if (areaId != null && areaId.isNotEmpty) {
      areaName = _areaCache[areaId];
      if (areaName == null) {
        try {
          final names = await _locations.fetchNamesByIds([areaId]);
          final area = names[areaId];
          if (area != null) {
            _areaCache[areaId] = area.localizedName();
            areaName = area.localizedName();
          }
        } catch (_) {
          areaName = null;
        }
      }
    }

    final summary = NotificationPropertySummary(
      title: property.title ?? '',
      areaName: areaName,
      purposeKey: 'purpose.${property.purpose.name}',
      coverImageUrl:
          property.coverImageUrl ??
          (property.imageUrls.isNotEmpty ? property.imageUrls.first : null),
      price: property.price,
    );
    _propertyCache[propertyId] = summary;
    return summary;
  }

  Future<String> _resolveRequesterName(AppNotification notification) async {
    if (notification.requesterName?.isNotEmpty == true) {
      return notification.requesterName!;
    }
    final requesterId = notification.requesterId;
    if (requesterId == null || requesterId.isEmpty) return '';
    if (_requesterCache.containsKey(requesterId)) {
      return _requesterCache[requesterId]!;
    }
    try {
      final user = await _usersRepository.getById(requesterId);
      final name = user.name?.isNotEmpty == true
          ? user.name!
          : (user.email?.isNotEmpty == true ? user.email! : '');
      _requesterCache[requesterId] = name;
      return name;
    } catch (_) {
      return '';
    }
  }

  Future<bool> _collectorCanOpenAccessRequest(
    AppNotification notification,
  ) async {
    final propertyId = notification.propertyId;
    if (propertyId == null || propertyId.isEmpty) return false;
    final property = await _propertiesRepository.getById(propertyId);
    if (property == null) return false;
    return property.ownerScope == PropertyOwnerScope.company;
  }

  bool _isAccessRequest(AppNotification notification) {
    final status = notification.requestStatus;
    final isAccessRequest =
        notification.type == AppNotificationType.accessRequest &&
        (notification.requestId?.isNotEmpty ?? false);
    if (!isAccessRequest) return false;
    if (status != null && status != AccessRequestStatus.pending) {
      return false;
    }
    return true;
  }

  bool _canShowAccessRequestDialog(
    AppNotification notification,
    UserRole? role,
    String? currentUserId,
    AppNotification? pendingTappedNotification,
  ) {
    if (!canShowAccessRequestDialog(role)) return false;
    if (notification.targetUserId != null &&
        notification.targetUserId!.isNotEmpty) {
      if (currentUserId == null || notification.targetUserId != currentUserId) {
        return false;
      }
    }
    if (pendingTappedNotification == null) {
      return true;
    }
    return pendingTappedNotification.id == notification.id;
  }
}

class NotificationRequestDialogPayload {
  NotificationRequestDialogPayload({
    required this.summary,
    required this.requesterName,
  });

  final NotificationPropertySummary summary;
  final String requesterName;
}

class ForegroundNotificationIntent {
  const ForegroundNotificationIntent({
    this.showDialog = false,
    this.dialogPayload,
    this.collectorAccessDenied = false,
  });

  final bool showDialog;
  final NotificationRequestDialogPayload? dialogPayload;
  final bool collectorAccessDenied;
}
