# UI Patterns (Repo-Specific)

## Page vs View vs Widgets
- **Pages** are route-level widgets that own blocs/cubits and high-level scaffolding.
  - Examples: `lib/features/notifications/presentation/pages/notifications_page.dart`, `lib/features/settings/presentation/pages/manage_locations_page.dart`, `lib/features/properties/presentation/pages/property_editor_page.dart`.
- **Views** are layout/composition layers used by pages to keep UI readable.
  - Examples: `lib/features/notifications/presentation/views/notifications_view.dart`, `lib/features/settings/presentation/views/manage_users_view.dart`.
- **Widgets** are reusable UI building blocks.
  - Examples: `lib/features/properties/presentation/widgets/property_card.dart`, `lib/features/notifications/presentation/widgets/notification_card.dart`, `lib/core/components/app_error_view.dart`.

## List Screen Standard (Properties)
- Standard list state lives in `lib/features/properties/presentation/widgets/property_paginated_list_view.dart`:
  - **Loading**: skeletons via `lib/core/components/app_skeletonizer.dart` + placeholders from `lib/features/properties/presentation/utils/property_placeholders.dart`.
  - **Empty**: `lib/core/components/empty_state_widget.dart`.
  - **Error + Retry**: `lib/core/components/app_error_view.dart`.
  - **Pull-to-refresh + load-more**: `SmartRefresher` from `pull_to_refresh`.
- Used by property list pages across features, including:
  - `lib/features/settings/presentation/pages/my_added_properties/my_added_properties_page.dart`
  - `lib/features/settings/presentation/pages/archive_properties/archive_properties_page.dart`
  - `lib/features/properties/presentation/pages/filtered_properties_page.dart`
  - `lib/features/company_areas/presentation/pages/company_area_properties/company_area_properties_page.dart`
  - `lib/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_page.dart`

## Dialogs and Bottom Sheets Policy
- Modal orchestration is centralized in flows (not in reusable widgets):
  - `lib/features/properties/presentation/flows/property_flow.dart`
  - `lib/features/settings/presentation/flows/manage_users_flow.dart`
  - `lib/features/notifications/presentation/flows/notification_flow.dart`
- Dialog and bottom-sheet UI lives under feature presentation folders:
  - Dialogs: `lib/features/**/presentation/dialogs/`
  - Bottom sheets: `lib/features/**/presentation/bottom_sheets/`
- Examples:
  - Property access request dialog: `lib/features/properties/presentation/dialogs/property_request_dialog.dart`
  - Create user bottom sheet: `lib/features/settings/presentation/bottom_sheets/create_company_user_bottom_sheet.dart`

## Selection and Bulk Actions
- Selection state is centralized in `lib/features/properties/presentation/selection/property_selection_controller.dart`.
- Bulk actions are configured via `lib/features/properties/presentation/selection/property_selection_policy.dart` and surfaced in `lib/features/properties/presentation/selection/selection_app_bar.dart`.
- Used across property list pages in settings, brokers, and company areas.

## Stable Keys and Testing Selectors
- Keys are used for widget tests and stable UI targeting:
  - Filters: `lib/features/categories/presentation/widgets/filter_bottom_sheet.dart`
  - Property access request dialog: `lib/features/properties/presentation/dialogs/property_request_dialog.dart`
  - Notification actions: `lib/features/notifications/presentation/widgets/notification_card/notification_card_actions.dart`
  - Manage users tabs: `lib/features/settings/presentation/views/manage_users_view.dart`
- Test helpers: `test/helpers/test_pump_utils.dart`.

## Accessibility + UX Consistency Checklist
Use this checklist for any new list or screen work:
- **Loading**: `AppSkeletonizer` or `AppSkeletonList` (`lib/core/components/app_skeletonizer.dart`, `lib/core/components/app_skeleton_list.dart`).
- **Empty**: `EmptyStateWidget` (`lib/core/components/empty_state_widget.dart`).
- **Error**: `AppErrorView` with retry (`lib/core/components/app_error_view.dart`).
- **Pull-to-refresh / pagination**: `SmartRefresher` in property lists (`lib/features/properties/presentation/widgets/property_paginated_list_view.dart`).
- **Consistent app bars**: `CustomAppBar` (`lib/core/components/custom_app_bar.dart`).
- **Background treatment**: `BaseGradientPage` where used (`lib/core/components/base_gradient_page.dart`).

## Anti-Patterns We Avoid (Guardrails)
- Presentation importing data-layer implementations (enforced by `tool/check_architecture.sh`).
- Firestore types outside data (`DocumentSnapshot`, `Timestamp` check enforced by `tool/check_architecture.sh`).
- Mixing Bloc and Cubit under a single feature’s presentation tree (enforced by `tool/check_architecture.sh`).
- Embedding modal logic directly inside shared widgets; prefer flows (`lib/features/**/presentation/flows/`).
