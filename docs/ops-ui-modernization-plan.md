# `/ops` UI modernization and coverage plan

## Scope

- Modernize the shared shell, page headers, buttons, table surfaces, status pills, dropdowns, and responsive layout without changing routes, data contracts, business rules, or existing selectors.
- Prioritize `/ops` and Tower screens while keeping shared controls safe for officer and other modules.
- Use the existing `base-nova` shadcn configuration and `@base-ui/react`; no dependency installation is required.

## Coverage gate

Every source file changed in this pass must have existing coverage extended or a focused test added in this session.

| Changed area | Coverage |
| --- | --- |
| `src/components/ui/*` | `src/components/ui/primitives.test.tsx` |
| `PageHeader`, `TableSurface`, `controls` | `PageHeader.test.tsx`, `TableSurface.test.tsx`, `controls.test.tsx` |
| status and table primitives | `StatusPill.test.tsx`, `DataTable.test.tsx`, `controls.test.tsx` |
| shell, language, tour, sign-out | `RootLayout.test.tsx`, `LanguageSwitch.test.tsx`, `TourButton.test.tsx`, `SignOutButton.test.tsx` |
| ops list and forms | existing screen tests plus `OpsRequestsScreen.test.tsx` |
| ops nested detail and review | `DemandDetailScreen.test.tsx`, `OpsRequestReviewScreen.test.tsx` |
| Tower overview and drill-downs | `TowerScreen.test.tsx`, `TowerDrillScreens.test.tsx` |
| officer people and registration | `PeopleScreen.test.tsx`, `RegisterScreen.test.tsx` |
| global styling | existing styles/token/contrast/depth/motion tests |

## Acceptance checks

- Custom Select controls support pointer and keyboard interaction and preserve test IDs.
- Nested pages expose a logical parent Back link and breadcrumbs with current-page semantics.
- Table surfaces are white, with filters/actions included in the same surface and horizontal scrolling limited to the table region.
- Status chips use solid semantic fills with readable contrast; hatching remains only on provisional/estimate indicators.
- Responsive checks cover 320, 375, 768, 1024, and 1440px without document-level horizontal overflow.
- Run `pnpm typecheck`, `pnpm lint`, `pnpm test`, and `pnpm e2e` before handoff.
