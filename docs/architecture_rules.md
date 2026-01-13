# Architectural Rules

## Layer Responsibilities
- **Presentation**: Widgets, pages, dialogs, bottom sheets, and minimal UI orchestration. No direct repository or service access.
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

## Additional Guardrails
- Dialogs/bottom sheets are presentation artifacts and must not contain business logic or repository calls.
- Any Firebase/storage logic belongs to data services.
- Avoid “god” widgets/pages longer than ~300 lines; split UI composition into smaller widgets and flows.
