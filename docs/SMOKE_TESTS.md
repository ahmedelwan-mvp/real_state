# Smoke Tests (Handoff)

## Must-Pass Routes
- `/settings/users` (owner only): list loads, create/disable/update flows open.
- `/settings/locations` (owner only): list loads, add/edit/delete dialogs open.
- `/properties/my-added`: list loads, selection works, share action opens.
- `/properties/archive`: list loads, selection works, restore/delete actions visible as allowed.
- `/broker/:id`: broker areas list loads and navigates to area.
- `/broker/:brokerId/area/:areaId`: property list loads, filter sheet opens, load more works.
- `/company/areas`: company areas list loads and navigates to area.
- `/company/area/:id`: property list loads, filter sheet opens, load more works.
- `/filters/categories`: filter page loads and applies filters.
- `/filters/results`: filtered list loads, clear returns.
- `/property/:id`: detail loads, images/phone/location visibility matches access.
- `/property/:id/images`: image viewer opens from detail.
- `/property/new` and `/property/:id/edit`: editor loads, save flow works.
- `/notifications`: list loads, accept/reject actions work for eligible roles.

## Role-Based Checks
- Owner:
  - Can access users/locations settings.
  - Can archive/delete properties.
  - Can accept/reject access requests.
- Broker:
  - Can access broker areas and broker property lists.
  - Cannot access users/locations settings.
- Collector:
  - Can access company areas and property lists.
  - Cannot access broker routes or users/locations settings.

## Expected Results (Short)
- Lists render with skeletons on load, empty state when no data, error state with retry.
- Pagination only loads more when `hasMore` is true.
- Access request dialogs open once and submit once per tap.
- Property detail actions honor role and access visibility rules.
- Editor validates fields and preserves existing values on edit.
