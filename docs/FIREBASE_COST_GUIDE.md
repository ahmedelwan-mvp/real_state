# Firebase Cost Guide

## Firebase Components in Use
| Component | Where used | Notes |
| --- | --- | --- |
| Auth | `lib/core/di/app_di.dart`, `lib/features/auth/data/` | Role-based access and session state. |
| Firestore | `lib/features/**/data/repositories/` | Primary data store (properties, users, access requests, notifications, location areas). |
| Storage | `lib/features/properties/data/services/property_upload_service_impl.dart`, `lib/features/location/data/repositories/location_repository_impl.dart` | Image uploads for properties and location areas. |
| Functions | `functions/src/index.ts`, `lib/features/notifications/data/services/fcm_service.dart` | Callable `sendNotification` for multicast. |
| FCM | `lib/features/notifications/data/services/fcm_service.dart` | Token management and message handling. |

## What Costs Money (Current Behavior)
### Firestore reads/writes
- Property lists use paginated queries with `limit` + cursor pagination in `lib/features/properties/data/repositories/properties_repository_impl.dart`.
- Access requests are read both via fetches and live snapshots in `lib/features/access_requests/data/repositories/access_requests_repository_impl.dart`.
- Notifications list fetches paginated documents per user in `lib/features/notifications/data/repositories/notifications_repository_impl.dart`.
- User management and location areas are stored in `users` and `location_areas` collections (`lib/core/constants/app_collections.dart`).

### Storage
- Property image uploads (compressed) via `PropertyUploadServiceImpl` in `lib/features/properties/data/services/property_upload_service_impl.dart`.
- Location area image uploads (compressed) via `LocationRepositoryImpl` in `lib/features/location/data/repositories/location_repository_impl.dart`.

### Cloud Functions
- Callable `sendNotification` invoked via `FirebaseFunctions` in `lib/features/notifications/data/services/fcm_service.dart`.
- Function definitions in `functions/src/index.ts` (ping + sendNotification).

### FCM (Messaging)
- Token reads/writes under `users/{uid}/fcmTokens` from `FcmService` (`lib/features/notifications/data/services/fcm_service.dart`).
- Multicast sends use the callable function; each invocation has cost and downstream FCM sends.

## Current Cost Guards Already in Code
- **Pagination limits**: properties and notifications use `limit` + `startAfterDocument` (`lib/features/properties/data/repositories/properties_repository_impl.dart`, `lib/features/notifications/data/repositories/notifications_repository_impl.dart`).
- **SingleFlightGuard**: prevents duplicate in-flight list requests (`lib/core/utils/single_flight_guard.dart`) in list blocs such as `lib/features/properties/presentation/bloc/lists/properties_bloc.dart`.
- **Token filtering + empty guard**: FCM delivery skips empty token lists and filters inactive tokens (`lib/features/notifications/data/services/fcm_service.dart`).
- **Token write dedupe**: avoids re-writing the same token (`lib/features/notifications/data/services/fcm_service.dart`).
- **Image compression**: reduces storage size and upload bandwidth (`lib/features/properties/data/services/property_upload_service_impl.dart`, `lib/features/location/data/repositories/location_repository_impl.dart`).
- **Location areas cache**: in-memory cache reduces repeated reads for lists (`lib/features/location/domain/location_areas_cache.dart`).

## Safe vs Risky Optimizations
**Safe (no behavior change if done carefully)**
- Use existing pagination guards (`SingleFlightGuard`) when adding new list loads.
- Reuse cached location data via `LocationAreasCache` instead of refetching.
- Avoid triggering refresh if list state is already up-to-date (stay within existing `Bloc` state transitions).
- Keep `limit` values the same and avoid adding new listeners.

**Risky (likely to change behavior or correctness)**
- Changing Firestore query shapes, filters, or orderBy (may require indexes and change results).
- Adding caching layers that skip server reads without explicit cache invalidation.
- Increasing `limit` or adding extra real-time listeners.
- Changing how access requests are watched (live snapshots are part of current behavior).

## Cost Audit Checklist (Pre-Release)
- Confirm list pages use cursor-based pagination with `limit` and no new listeners.
- Check for duplicate network calls on refresh/load-more (ensure `SingleFlightGuard` or equivalent).
- Verify access request watchers are scoped to a single property detail view.
- Ensure storage uploads are compressed and do not store duplicate images.
- Ensure FCM sends skip empty token lists and remove inactive tokens.
- Confirm Cloud Functions deployment region matches client callable region (`us-central1`).

## Measurement Approach (No New Logging)
- Use Firebase Console metrics:
  - Firestore reads/writes by collection (`properties`, `users`, `notifications`, `access_requests`, `location_areas`).
  - Storage usage and egress.
  - Functions invocation counts and errors.
- Use existing debug logs in data/services (e.g., notifications fetch logs in `lib/features/notifications/data/repositories/notifications_repository_impl.dart`) during QA builds.
- Track pagination behavior in QA by observing UI load-more and refresh cycles (no new logging required).
