# Architecture Overview

## App Purpose and Roles
- Purpose: internal property tracking and access-control app for company staff (not public-facing). Source: `README_NON_TECH.md`.
- Roles are defined in `lib/core/constants/user_role.dart`:
  - Owner: full control over properties, users, and access decisions.
  - Collector: captures property info and can update properties they created or were assigned.
  - Broker: works with broker-scoped properties; similar permissions to collectors with broker scope.

## High-Level Flows (current implementation)
### Property create/edit/upload
- Entry points: `lib/features/properties/presentation/pages/property_editor_page.dart` and `lib/features/properties/presentation/pages/property_editor_actions.dart`.
- Use cases: `lib/features/properties/domain/usecases/create_property_usecase.dart`, `lib/features/properties/domain/usecases/update_property_usecase.dart`.
- Image upload + cleanup: `lib/features/properties/domain/usecases/upload_property_images_usecase.dart`, `lib/features/properties/domain/usecases/delete_property_images_usecase.dart`.
- Mutation broadcast to lists: `lib/features/properties/presentation/side_effects/property_mutations_bloc.dart`.
- Property-added notifications: `lib/features/notifications/domain/repositories/notifications_repository.dart` and `lib/features/notifications/data/repositories/notifications_repository_impl.dart`.

### Browse/filter/paginate
- List state + pagination guard: `lib/features/properties/presentation/bloc/lists/properties_bloc.dart` and `lib/core/utils/single_flight_guard.dart`.
- Data fetch and cursor pagination: `lib/features/properties/data/repositories/properties_repository_impl.dart`.
- Filter model: `lib/features/categories/domain/entities/property_filter.dart`.
- List UI standard: `lib/features/properties/presentation/widgets/property_paginated_list_view.dart`.
- Filtered results route: `lib/features/properties/presentation/pages/filtered_properties_page.dart`.

### Access requests (images/phone/location)
- Request creation + validation: `lib/features/access_requests/domain/usecases/create_access_request_usecase.dart`.
- Data access and watchers: `lib/features/access_requests/data/repositories/access_requests_repository_impl.dart`.
- UI request dialog + flow entry: `lib/features/properties/presentation/dialogs/property_request_dialog.dart` and `lib/features/properties/presentation/flows/property_flow.dart`.
- Access status driven from property detail state: `lib/features/properties/presentation/bloc/detail/property_detail_bloc.dart`.

### Notifications + actions + deep links
- Messaging + token lifecycle: `lib/features/notifications/data/services/fcm_service.dart`.
- Cloud Function endpoint used for multicast: `functions/src/index.ts` (callable `sendNotification`).
- Foreground/tap handling + deep link routing to properties: `lib/features/notifications/presentation/flows/notification_flow.dart`.
- Notifications list + actions: `lib/features/notifications/presentation/bloc/notifications_bloc.dart` and `lib/features/notifications/presentation/views/notifications_view.dart`.

### Sharing images/PDF + bulk share overlay
- Share service + PDF generation: `lib/features/properties/domain/services/property_share_service.dart`.
- Bulk share helper + overlay controller: `lib/features/properties/presentation/utils/multi_pdf_share.dart` and `lib/features/properties/presentation/widgets/property_share_progress_overlay.dart`.
- Detail page triggers share events: `lib/features/properties/presentation/pages/property_detail/property_page_body.dart` and `lib/features/properties/presentation/flows/property_flow.dart`.

### Manage users/locations/settings
- Settings shell + pages: `lib/features/settings/presentation/pages/settings_page.dart`.
- Manage users flow/view: `lib/features/settings/presentation/flows/manage_users_flow.dart`, `lib/features/settings/presentation/views/manage_users_view.dart`.
- Manage locations page (uses location widgets): `lib/features/settings/presentation/pages/manage_locations_page.dart`.

## Clean Architecture Rules (enforced)
Defined in `docs/architecture_rules.md` and enforced by `tool/check_architecture.sh`:
- Presentation can import domain and core, but not data.
- Domain cannot import data.
- Firebase types (`DocumentSnapshot`, `Timestamp`) are only allowed in data.
- Each feature declares a single state-management paradigm (Bloc or Cubit) under presentation.
- Side effects are allowed under `presentation/side_effects/` and are not listened to directly by widgets.
- Use case orchestration is allowed in `presentation/flows/`; pages/widgets should not invoke use cases directly.

## State Ownership and Side Effects
- One state paradigm per feature (per `docs/architecture_rules.md`).
- Snackbars and modal orchestration live in flows:
  - `lib/features/properties/presentation/flows/property_flow.dart`
  - `lib/features/notifications/presentation/flows/notification_flow.dart`
  - `lib/features/settings/presentation/flows/manage_users_flow.dart`
- Mutation broadcasts for lists are centralized in `lib/features/properties/presentation/side_effects/property_mutations_bloc.dart`, which implements `lib/features/properties/domain/services/property_mutations_stream.dart`.
- Pagination guards are centralized in `lib/core/utils/single_flight_guard.dart` and used by list blocs.

## Dependency Injection (DI)
- Central registration: `lib/core/di/app_di.dart`.
- App wiring and provider tree: `lib/app.dart` (MultiProvider + SettingsCubit).
- Patterns in use:
  - Repositories + use cases registered in `AppDi` and injected with `RepositoryProvider`.
  - Blocs/cubits created inside pages or passed via `BlocProvider.value` when routing.

## Routing Model
- GoRouter configuration: `lib/core/routes/app_router.dart`.
- Route guards and role-based redirects: `lib/core/routes/route_guards.dart`.
- Auth refresh-based redirects: `AuthRepository` is a `ChangeNotifier` passed to `GoRouter` (`lib/core/auth/auth_repository.dart`, `lib/core/routes/app_router.dart`).

## Feature Map
| Feature | Layers present | State management | Special boundaries / notes |
| --- | --- | --- | --- |
| access_requests | data, domain | none | repositories + use cases only (`lib/features/access_requests/`). |
| auth | data, domain, presentation | Cubit | login pages/widgets (`lib/features/auth/presentation/`). |
| brokers | data, domain, presentation | Bloc | areas + broker properties pages (`lib/features/brokers/presentation/`). |
| categories | data, domain, presentation | Cubit | filter bottom sheet + pages (`lib/features/categories/presentation/`). |
| company_areas | data, domain, presentation | Bloc | company area list + properties page (`lib/features/company_areas/presentation/`). |
| location | data, domain, presentation (widgets only) | none | shared location widgets used across features (`lib/features/location/presentation/widgets/`). |
| main_shell | presentation | none | shell tabs + home composition (`lib/features/main_shell/presentation/`). |
| models | entities only | none | shared entity definitions (`lib/features/models/entities/`). |
| notifications | data, domain, presentation | Bloc | flows, dialogs, views, widgets (`lib/features/notifications/presentation/`). |
| properties | models, data, domain, presentation | Bloc | flows, dialogs, selection, side_effects (`lib/features/properties/presentation/`). |
| settings | data, domain, presentation | Cubit | flows, dialogs, bottom_sheets, views (`lib/features/settings/presentation/`). |
| splash | presentation | Cubit | splash screen (`lib/features/splash/presentation/`). |
| users | data, domain | none | repositories + use cases only (`lib/features/users/`). |

## Cross-Feature Dependencies (observed)
- Shell composition imports feature presentation blocs/pages:
  - `lib/features/main_shell/presentation/pages/home_page.dart`
  - `lib/features/main_shell/presentation/pages/main_shell_page.dart`
- Settings uses brokers list state and location UI widgets:
  - `lib/features/settings/presentation/views/manage_users_view.dart`
  - `lib/features/settings/presentation/pages/manage_locations_page.dart`
- Categories UI uses property presentation widgets and selection helpers:
  - `lib/features/categories/presentation/widgets/category_property_card.dart`
  - `lib/features/categories/presentation/pages/categories_page.dart`
- Broker/Company property screens reuse properties selection + list UI:
  - `lib/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_page.dart`
  - `lib/features/company_areas/presentation/pages/company_area_properties/company_area_properties_page.dart`
- Properties editor uses location UI and notifications domain:
  - `lib/features/properties/presentation/pages/property_editor_page.dart`

Domain-level cross-feature usage also exists (e.g., property filters from categories):
- `lib/features/properties/domain/usecases/get_company_properties_page_usecase.dart`
- `lib/features/properties/domain/usecases/get_broker_properties_page_usecase.dart`

## What to Do / What NOT to Do
**Do**
- Keep Firebase types inside data implementations only (see `docs/architecture_rules.md`).
- Keep side effects in flows or `presentation/side_effects/` and re-emit results through feature blocs/cubits.
- Use DI from `AppDi` instead of instantiating repositories directly in widgets.
- Keep one state-management paradigm per feature (Bloc or Cubit) under presentation.

**Do NOT**
- Import `data/` from `presentation/` or `domain/` (enforced by `tool/check_architecture.sh`).
- Add Firestore types outside data.
- Mix `presentation/bloc` and `presentation/cubit` within the same feature.
- Add new direct Firebase calls in presentation; keep them in data services.

## Refactor-Safe Guidelines
- Keep GoRouter paths stable (`lib/core/routes/app_router.dart`) unless the change is explicitly a routing change.
- Preserve domain contracts (entities + use cases) in `lib/features/**/domain/`.
- When moving UI, update DI providers and route imports but avoid logic changes.
- Run `tool/check_architecture.sh`, `flutter analyze`, and `flutter test -r expanded` after refactors.
