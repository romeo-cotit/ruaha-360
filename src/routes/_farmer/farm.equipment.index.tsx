import { createFileRoute } from '@tanstack/react-router'

import { EquipmentListScreen } from '@/features/farmer/EquipmentListScreen'
import { validateResourceSearch } from '@/features/farmer/resourceKind'

export const Route = createFileRoute('/_farmer/farm/equipment/')({
  // Equipment or loans, held in the URL so a link lands on the same list.
  validateSearch: validateResourceSearch,
  component: EquipmentListScreen,
})
