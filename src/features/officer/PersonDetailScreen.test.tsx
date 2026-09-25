import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, test, vi } from 'vitest'

const usePersonDetail = vi.fn()
const useVerify = vi.fn()
const useCrops = vi.fn()
const mutate = vi.fn()
const reset = vi.fn()
const editMutate = vi.fn()
const editReset = vi.fn()
const queryState: { data: unknown; error: Error | null; isLoading: boolean; refetch: ReturnType<typeof vi.fn> } = {
  data: null,
  error: null,
  isLoading: false,
  refetch: vi.fn(),
}
const verifyState = {
  isPending: false,
  variables: undefined as { table: string; id: string } | undefined,
  isError: false,
  error: null as Error | null,
}

vi.mock('@tanstack/react-router', () => ({
  getRouteApi: () => ({ useParams: () => ({ personId: 'p1' }) }),
}))
vi.mock('@/features/officer/usePersonDetail', () => ({
  usePersonDetail: () => usePersonDetail(),
  useVerify: () => useVerify(),
}))
vi.mock('@/features/officer/useCrops', () => ({ useCrops: () => useCrops() }))
vi.mock('@/features/officer/useOfficerEdit', () => ({
  useOfficerEdit: () => ({ mutateAsync: editMutate, reset: editReset, isPending: false, error: null }),
}))
vi.mock('@/features/officer/VerifyButton', () => ({
  VerifyButton: ({ table, id, onVerify }: { table: string; id: string; onVerify: (value: { table: string; id: string }) => void }) => (
    <button type="button" data-testid={`verify-${table}-${id}`} onClick={() => onVerify({ table, id })}>Verify</button>
  ),
}))
vi.mock('@/features/officer/OfficerEditDialog', () => ({
  OfficerEditDialog: ({ table, version, initialValues, onSave, onComplete, onCancel }: { table: string; version?: string | null; initialValues: Record<string, string>; onSave: (values: Record<string, string>) => Promise<unknown> | void; onComplete?: () => void; onCancel: () => void }) => (
    <div data-testid={`screen-edit-${table}`} data-version={version ?? ''}>
      <button type="button" data-testid="screen-edit-save" onClick={async () => { try { await onSave(initialValues); onComplete?.() } catch { /* stays open */ } }}>Save</button>
      <button type="button" data-testid="screen-edit-cancel" onClick={onCancel}>Cancel</button>
    </div>
  ),
}))

const { PersonDetailScreen } = await import('@/features/officer/PersonDetailScreen')
await import('@/i18n')

const provenance = (verification: 'unverified' | 'pending' | 'verified' | 'disputed' = 'verified') => ({
  source: 'field_verified' as const,
  verification,
  confidence: null,
  captured_at: '2026-09-20T00:00:00Z',
  captured_by: null,
  verified_by: null,
  verified_at: null,
})

function detail(over: Record<string, unknown> = {}) {
  const areaCycle = {
    id: 'c-area', crop_id: 'crop-area', crop_name: 'Maize', season_label: 'Season', area_ha: 1, tree_count: null, unit_count: null,
    planted_on: '2026-01-01', harvest_start: '2026-08-01', harvest_end: '2026-09-01', status: 'growing' as const,
    ...provenance('pending'), harvests: [
      { id: 'h-current', kind: 'expected' as const, quantity_kg: 100, is_current: true, reported_for: '2026-08-02', ...provenance('unverified') },
      { id: 'h-old', kind: 'expected' as const, quantity_kg: 90, is_current: false, reported_for: null, ...provenance('verified') },
    ],
  }
  const treeCycle = {
    id: 'c-tree', crop_id: 'crop-tree', crop_name: 'Avocado', season_label: null, area_ha: null, tree_count: 12, unit_count: null,
    planted_on: null, harvest_start: null, harvest_end: null, status: 'planned' as const,
    ...provenance('verified'), harvests: [
      { id: 'h-tree-current', kind: 'actual' as const, quantity_kg: 8, is_current: true, reported_for: null, ...provenance('pending') },
    ],
  }
  const unitCycle = {
    id: 'c-unit', crop_id: 'crop-unit', crop_name: 'Eggs', season_label: 'Units', area_ha: null, tree_count: null, unit_count: 5,
    planted_on: null, harvest_start: null, harvest_end: null, status: 'harvested' as const,
    ...provenance('verified'), harvests: [],
  }
  return {
    person: { id: 'p1', given_name: 'Neema', family_name: 'Mwakalinga', phone: '0700', village_id: 'v1', ...provenance('unverified') },
    households: [{ id: 'hhold', label: 'Household', members: [{ id: 'p1', given_name: 'Neema', family_name: 'Mwakalinga' }], ...provenance('verified') }],
    farms: [{
      id: 'farm1', label: 'Farm', latitude: -8, longitude: 35, ...provenance('verified'),
      plots: [{ id: 'plot1', label: 'Plot', area_ha: 1.2, latitude: null, longitude: null, ...provenance('pending'), cycles: [areaCycle, treeCycle, unitCycle] }],
    }],
    ...over,
  }
}

beforeEach(() => {
  queryState.data = detail()
  queryState.error = null
  queryState.isLoading = false
  verifyState.isPending = false
  verifyState.variables = undefined
  verifyState.isError = false
  verifyState.error = null
  usePersonDetail.mockReturnValue(queryState)
  useVerify.mockReturnValue({ ...verifyState, mutate, reset })
  useCrops.mockReturnValue({ crops: [
    { id: 'crop-area', name: 'Maize', measured_by: 'area' },
    { id: 'crop-tree', name: 'Avocado', measured_by: 'tree_count' },
    { id: 'crop-unit', name: 'Eggs', measured_by: 'unit_count' },
  ] })
  mutate.mockReset()
  reset.mockReset()
  editMutate.mockReset()
  editReset.mockReset()
})

describe('PersonDetailScreen', () => {
  test('renders the full graph and every section edit action', async () => {
    const user = userEvent.setup()
    verifyState.isPending = true
    verifyState.variables = { table: 'person', id: 'p1' }
    useVerify.mockReturnValue({ ...verifyState, mutate, reset })
    render(<PersonDetailScreen />)
    expect(screen.getByTestId('person-detail')).toHaveTextContent('Neema Mwakalinga')
    expect(screen.getByTestId('household-hhold')).toHaveTextContent('Household')
    expect(screen.getByTestId('farm-farm1')).toHaveTextContent('Farm')
    expect(screen.getByTestId('harvest-h-old')).toHaveTextContent('Superseded')

    for (const id of ['edit-person', 'edit-household-hhold', 'edit-farm-farm1', 'edit-plot-plot1', 'edit-cycle-c-area', 'edit-cycle-c-tree', 'edit-cycle-c-unit', 'edit-harvest-h-current', 'edit-harvest-h-tree-current']) {
      await user.click(screen.getByTestId(id))
      expect(screen.getByTestId(/screen-edit-(person|household|farm|plot|crop_cycle|harvest_report)$/)).toBeInTheDocument()
      await user.click(screen.getByTestId('screen-edit-cancel'))
    }
    expect(editReset).toHaveBeenCalled()
  })

  // A season the officer can edit must also be visible where they edit it.
  test('a cycle shows its season beside the crop', () => {
    render(<PersonDetailScreen />)
    expect(screen.getByTestId('cycle-c-area')).toHaveTextContent('Maize · Season')
    expect(screen.getByTestId('cycle-c-tree')).toHaveTextContent('Avocado')
    expect(screen.getByTestId('cycle-c-tree')).not.toHaveTextContent('Avocado ·')
  })

  test('saves a section through the mutation and closes after success', async () => {
    const user = userEvent.setup()
    render(<PersonDetailScreen />)
    await user.click(screen.getByTestId('edit-person'))
    await user.click(screen.getByTestId('screen-edit-save'))
    expect(editMutate).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByTestId('screen-edit-person')).not.toBeInTheDocument())
  })

  // The payload drops measures the crop does not use, so the save must name
  // the measure of the crop currently selected in the dialog.
  test('a cycle save passes the selected crop measure', async () => {
    const user = userEvent.setup()
    render(<PersonDetailScreen />)
    await user.click(screen.getByTestId('edit-cycle-c-tree'))
    await user.click(screen.getByTestId('screen-edit-save'))
    expect(editMutate).toHaveBeenCalledWith(expect.objectContaining({ table: 'crop_cycle', id: 'c-tree', measure: 'tree_count' }))
  })

  // A draft is discarded when the record changed since it was written, so
  // the dialog must be told which server version it is editing.
  test('each edit dialog is given the record captured_at as its draft version', async () => {
    const user = userEvent.setup()
    render(<PersonDetailScreen />)
    await user.click(screen.getByTestId('edit-person'))
    expect(screen.getByTestId('screen-edit-person')).toHaveAttribute('data-version', '2026-09-20T00:00:00Z')
  })

  test('a failed section save stays open', async () => {
    const user = userEvent.setup()
    editMutate.mockRejectedValueOnce(new Error('refused'))
    render(<PersonDetailScreen />)
    await user.click(screen.getByTestId('edit-person'))
    await user.click(screen.getByTestId('screen-edit-save'))
    expect(screen.getByTestId('screen-edit-person')).toBeInTheDocument()
  })

  test('handles loading, not-found, read error, and verify error states', async () => {
    queryState.isLoading = true
    const view = render(<PersonDetailScreen />)
    expect(screen.getByTestId('person-loading')).toBeInTheDocument()

    queryState.isLoading = false
    queryState.data = null
    view.rerender(<PersonDetailScreen />)
    expect(screen.getByTestId('empty-state')).toBeInTheDocument()

    queryState.data = detail()
    queryState.error = new Error('read failed')
    view.rerender(<PersonDetailScreen />)
    expect(screen.getByTestId('error-state')).toHaveTextContent('read failed')
    await userEvent.setup().click(screen.getByTestId('error-retry'))
    expect(queryState.refetch).toHaveBeenCalled()

    queryState.error = null
    verifyState.isError = true
    verifyState.error = new Error('verify failed')
    useVerify.mockReturnValue({ ...verifyState, mutate, reset })
    view.rerender(<PersonDetailScreen />)
    expect(screen.getByTestId('verify-error')).toHaveTextContent('verify failed')
    await userEvent.setup().click(screen.getByTestId('error-retry'))
    expect(reset).toHaveBeenCalled()
  })

  test('renders empty relationship sections and fully verified summary', () => {
    queryState.data = {
      ...detail({ households: [], farms: [] }),
      person: { ...detail().person, phone: null, verification: 'verified' },
    }
    render(<PersonDetailScreen />)
    expect(screen.getByTestId('person-outstanding')).toHaveTextContent('Every record here is verified')
    expect(screen.getAllByTestId('empty-state')).toHaveLength(2)
  })

  test('preloads nullable correction fields', async () => {
    const user = userEvent.setup()
    const base = detail()
    queryState.data = {
      ...base,
      farms: [{
        ...base.farms[0],
        latitude: null,
        longitude: null,
        plots: [{ ...base.farms[0].plots[0], area_ha: null, latitude: 1, longitude: 2, cycles: [] }],
      }],
      person: { ...base.person, phone: null },
    }
    render(<PersonDetailScreen />)
    await user.click(screen.getByTestId('edit-person'))
    await user.click(screen.getByTestId('screen-edit-cancel'))
    await user.click(screen.getByTestId('edit-farm-farm1'))
    await user.click(screen.getByTestId('screen-edit-cancel'))
    await user.click(screen.getByTestId('edit-plot-plot1'))
    await user.click(screen.getByTestId('screen-edit-cancel'))
  })
})
