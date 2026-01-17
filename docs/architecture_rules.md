# Architectural Rules

## Layer Responsibilities
- **Presentation**: Widgets, pages, dialogs, bottom sheets, and minimal UI orchestration. No direct repository or service access. Use case orchestration is allowed in `presentation/flows/` only.
- **Domain**: Entities, repository abstractions, use cases, and pure services. No references to concrete data implementations.
- **Data**: Models, data sources, service implementations (Firebase/HTTP), and repository implementations that depend on domain contracts.

## Allowed Imports
- Presentation may import domain (use cases/entities) and core/common widgets/utilities. It must not import data or infrastructure.
- Domain may import only core, domain contracts, and utilities. It cannot import data repositories.
- Data may import domain interfaces, models, core utilities, and external packages (Firebase, HTTP, etc.).

## Feature Folder Template
```
feature/
├─ data/
│  ├─ datasources/
│  ├─ models/
│  ├─ repositories/
│  └─ services/        # infra
├─ domain/
│  ├─ entities/
│  ├─ repositories/    # interfaces only
│  ├─ usecases/
│  └─ services/        # pure domain helpers
└─ presentation/
   ├─ bloc/            # Bloc or Cubit, not both
   ├─ pages/
   ├─ widgets/
   ├─ dialogs/
   ├─ bottom_sheets/
   └─ flows/            # orchestration only
```

## State Management Rule
- Each feature must declare a single state management paradigm (Bloc or Cubit). Mixing both or adding custom controllers that tap repositories is forbidden.
- Side-effect helpers are allowed only under `presentation/side_effects/` and must not be listened to by widgets. Their output must be re-emitted through the feature’s main Bloc/Cubit.

## Additional Guardrails
- Pages/widgets must not invoke use cases directly; route those actions through flows or feature blocs/cubits.
- Dialogs/bottom sheets are presentation artifacts and must not contain business logic or repository calls.
- Any Firebase/storage logic belongs to data services.
- Avoid “god” widgets/pages longer than ~300 lines; split UI composition into smaller widgets and flows.

## Enforcement Script
Run:
```
tool/check_architecture.sh
```

### Enforced Rules
- Any file under `lib/features/**/presentation` importing `lib/features/**/data` fails.
- Any file under `lib/features/**/domain` importing `lib/features/**/data` fails.
- Any Firestore types (`DocumentSnapshot`, `Timestamp`) referenced outside `lib/**/data/**` fail.
- Any feature containing both `presentation/**/bloc` and `presentation/**/cubit` fails.
