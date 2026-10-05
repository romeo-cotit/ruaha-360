import { createFileRoute } from '@tanstack/react-router'

import { CatalogueScreen } from '@/features/ops/CatalogueScreen'
import { validateResourceSearch } from '@/features/farmer/resourceKind'

export const Route = createFileRoute('/_ops/ops/catalogue')({
  // Equipment or loans, held in the URL so a link lands on the same list.
  validateSearch: validateResourceSearch,
  component: CatalogueScreen,
})
