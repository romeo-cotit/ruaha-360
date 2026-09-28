import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'

const useSession = vi.fn()
const useCrops = vi.fn()
const useDraft = vi.fn()
const rpc = vi.fn()
const navigate = vi.fn()
const save = vi.fn()
const clear = vi.fn()

vi.mock('@tanstack/react-router', () => ({
  getRouteApi: () => ({ useSearch: () => ({ draft: 'draft-ref-1' }) }),
  useNavigate: () => navigate,
  Link: ({ children }: { children: React.ReactNode }) => <a href="#x">{children}</a>,
}))
vi.mock('@/app/session', () => ({ useSession: () => useSession() }))
vi.mock('@/features/officer/useCrops', () => ({ useCrops: () => useCrops() }))
const useDraftArgs: unknown[][] = []
vi.mock('@/lib/drafts', () => ({
  draftKey: (a: string, b: string) => `${a}:${b}`,
  indexedDbDraftStore: { get: vi.fn(), set: vi.fn(), clear: vi.fn() },
  useDraft: (...args: unknown[]) => {
    useDraftArgs.push(args)
    return useDraft()
  },
}))
vi.mock('@/lib/supabase', () => ({ supabase: { rpc: (...args: unknown[]) => rpc(...args) } }))

const { RegisterScreen } = await import('@/features/officer/RegisterScreen')
const { isRegisterDraft } = await import('@/features/officer/registerSchema')
await import('@/i18n')

/** A shape-valid empty draft, for the restore tests. */
const EMPTY_DRAFT = {
  given_name: '',
  family_name: '',
  phone: '',
  household_label: '',
  is_head: true,
  farm_label: '',
  farm_latitude: '',
  farm_longitude: '',
  plot_label: '',
  plot_area_ha: '',
  crop_id: '',
  season_label: '',
  cycle_area_ha: '',
  cycle_tree_count: '',
  cycle_unit_count: '',
  planted_on: '',
  harvest_start: '',
  harvest_end: '',
  harvest_quantity_kg: '',
  confidence: 'medium',
}

const VILLAGE = '30000000-0000-4000-8000-000000000001'
const MAIZE = '40000000-0000-4000-8000-000000000001'
const COFFEE = '40000000-0000-4000-8000-000000000003'

beforeEach(() => {
  rpc.mockReset()
  navigate.mockReset()
  save.mockReset()
  clear.mockReset()
  useSession.mockReturnValue({
    isLoading: false,
    error: null,
    data: {
      appUser: { id: 'u1', person_id: null },
      memberships: [
        { id: 'm1', role: 'field_officer', project_id: 'p1', village_id: VILLAGE, revoked_at: null },
      ],
    },
  })
  useCrops.mockReturnValue({
    isLoading: false,
    error: null,
    crops: [
      { id: MAIZE, name: 'Mahindi', measured_by: 'area' },
      { id: COFFEE, name: 'Kahawa', measured_by: 'tree_count' },
    ],
  })
  useDraft.mockReturnValue({ status: 'clean', draft: null, save, clear })
  rpc.mockResolvedValue({ data: { person_id: 'new-person' }, error: null })
})

function renderScreen() {
  const client = new QueryClient({ defaultOptions: { mutations: { retry: false } } })
  return render(
    <QueryClientProvider client={client}>
      <RegisterScreen />
    </QueryClientProvider>,
  )
}

/** Fills a complete, valid registration. */
async function chooseCrop(label: string) {
  await userEvent.click(screen.getByTestId('register-crop'))
  await userEvent.click(await screen.findByRole('option', { name: label }))
}

async function fillValid() {
  fireEvent.change(screen.getByTestId('register-given-name'), { target: { value: 'Neema' } })
  fireEvent.change(screen.getByTestId('register-family-name'), { target: { value: 'Mwakalinga' } })
  fireEvent.change(screen.getByTestId('register-phone'), { target: { value: '+255700000101' } })
  fireEvent.change(screen.getByTestId('register-farm-label'), { target: { value: 'Shamba' } })
  // jsdom has no GPS, so the location fields stay open for typing — the same
  // fallback an officer gets when the handset refuses a position.
  fireEvent.change(screen.getByTestId('register-farm-latitude'), { target: { value: '-8.1303' } })
  fireEvent.change(screen.getByTestId('register-farm-longitude'), { target: { value: '35.1895' } })
  fireEvent.change(screen.getByTestId('register-plot-label'), { target: { value: 'Kipande' } })
  await chooseCrop('Mahindi')
  fireEvent.change(screen.getByTestId('register-cycle-area'), { target: { value: '1.6' } })
}

const submit = () => fireEvent.click(screen.getByTestId('register-submit'))

/**
 * QA #16 and #17. `required: true` rejected `""` and accepted `"   "`, and
 * `person.given_name` is `not null` — which `'   '` satisfies. A farmer could
 * be registered with a blank name, on a screen with no rename to fix it.
 */
describe('whitespace-only names', () => {
  test('are refused inline, and never reach the RPC', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-given-name'), { target: { value: '   ' } })
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-given-name-error')).toBeInTheDocument(),
    )
    expect(rpc).not.toHaveBeenCalled()
  })

  test('and the value that is stored is the trimmed one', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-given-name'), { target: { value: '  Neema  ' } })
    submit()

    await waitFor(() => expect(rpc).toHaveBeenCalledTimes(1))
    const payload = rpc.mock.calls[0][1].payload as { person: { given_name: string } }
    expect(payload.person.given_name).toBe('Neema')
  })
})

/**
 * QA #19. The measure field is rendered conditionally on `crop.measured_by`,
 * and was the one field with no check — so the RPC's own prose was doing an
 * inline message's job, one round trip later.
 */
describe('the conditional measure field', () => {
  test('is required for the crop that uses it', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-cycle-area'), { target: { value: '' } })
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-cycle-area-ha-error')).toBeInTheDocument(),
    )
    expect(rpc).not.toHaveBeenCalled()
  })

  test('follows the crop: a tree crop asks for trees', async () => {
    renderScreen()
    await fillValid()
    await chooseCrop('Kahawa')
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-cycle-tree-count-error')).toBeInTheDocument(),
    )
    expect(screen.queryByTestId('register-cycle-area-ha-error')).not.toBeInTheDocument()
  })
})

/**
 * QA #21. `cycle_window_sane` caught this and its constraint NAME was rendered
 * as user copy.
 */
describe('the harvest window', () => {
  test('a backwards window is caught inline, on the end date', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-harvest-start'), {
      target: { value: '2026-09-30' },
    })
    fireEvent.change(screen.getByTestId('register-harvest-end'), {
      target: { value: '2026-09-01' },
    })
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-harvest-end-error')).toBeInTheDocument(),
    )
    expect(rpc).not.toHaveBeenCalled()
  })

  // A constraint identifier is not user copy — that is the whole point of
  // catching this here.
  test('and says what is wrong in words', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-harvest-start'), {
      target: { value: '2026-09-30' },
    })
    fireEvent.change(screen.getByTestId('register-harvest-end'), {
      target: { value: '2026-09-01' },
    })
    submit()

    const error = await screen.findByTestId('register-harvest-end-error')
    expect(error).toHaveTextContent(/harvest window must end/i)
    expect(error).not.toHaveTextContent(/cycle_window_sane|register\./)
  })
})

/**
 * One message per reason. A single "This is required." under every field was
 * what made #16 and #19 hard to see: the form could only say "something".
 */
describe('the message names the actual problem', () => {
  test('text in a number field says so', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-harvest-kg'), { target: { value: 'abc' } })
    submit()

    const error = await screen.findByTestId('register-harvest-quantity-kg-error')
    expect(error).toHaveTextContent(/enter a number/i)
  })

  test('a number too big for its column says that, rather than overflowing', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-harvest-kg'), {
      target: { value: '999999999999' },
    })
    submit()

    const error = await screen.findByTestId('register-harvest-quantity-kg-error')
    expect(error).toHaveTextContent(/too large/i)
    expect(rpc).not.toHaveBeenCalled()
  })

  test('an empty required field still says it is required', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-family-name'), { target: { value: '' } })
    submit()

    const error = await screen.findByTestId('register-family-name-error')
    expect(error).toHaveTextContent(/required/i)
  })
})

/**
 * QA #28. The phone is now the farmer's login name, so it is required. Its
 * FORMAT is still not checked here: app_normalize_phone decides what a
 * Tanzanian mobile is, and a client copy of that rule would drift.
 */
describe('the phone field', () => {
  test('is required, and never reaches the RPC blank', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-phone'), { target: { value: '  ' } })
    submit()

    await waitFor(() => expect(screen.getByTestId('register-phone-error')).toBeInTheDocument())
    expect(rpc).not.toHaveBeenCalled()
  })

  test('shows the format the programme uses, and leaves checking it to the database', async () => {
    renderScreen()

    expect(screen.getByTestId('register-phone-hint')).toHaveTextContent(/\+255/)

    await fillValid()
    fireEvent.change(screen.getByTestId('register-phone'), { target: { value: '0700 000 101' } })
    submit()

    // Another spelling of a Tanzanian mobile: the database normalises it.
    await waitFor(() => expect(rpc).toHaveBeenCalledTimes(1))
  })
})

describe('the farm location', () => {
  test('is required: a registration without it never reaches the RPC', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-farm-latitude'), { target: { value: '' } })
    fireEvent.change(screen.getByTestId('register-farm-longitude'), { target: { value: '' } })
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-farm-latitude-error')).toBeInTheDocument(),
    )
    expect(rpc).not.toHaveBeenCalled()
  })
})

/**
 * QA #27. `hectares` is `numeric(10,4)`, so 1.23456789 is stored as 1.2346 —
 * correctly, and silently. The operator typed one number and the record holds
 * another.
 */
describe('silent rounding', () => {
  test('says what will actually be stored', () => {
    renderScreen()
    fireEvent.change(screen.getByTestId('register-plot-area'), {
      target: { value: '1.23456789' },
    })

    expect(screen.getByTestId('register-plot-area-rounded')).toHaveTextContent('1.2346')
  })

  test('says nothing when nothing changes', () => {
    renderScreen()
    fireEvent.change(screen.getByTestId('register-plot-area'), { target: { value: '1.8' } })

    expect(screen.queryByTestId('register-plot-area-rounded')).not.toBeInTheDocument()
  })

  // quantity_kg is numeric(12,2) — a different scale on the same form.
  test('uses each column own scale', () => {
    renderScreen()
    fireEvent.change(screen.getByTestId('register-harvest-kg'), { target: { value: '4100.567' } })

    expect(screen.getByTestId('register-harvest-kg-rounded')).toHaveTextContent('4100.57')
  })
})

describe('a valid registration', () => {
  test('is not newly blocked by any of this', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-phone'), { target: { value: '+255700000101' } })
    fireEvent.change(screen.getByTestId('register-plot-area'), { target: { value: '1.8' } })
    fireEvent.change(screen.getByTestId('register-harvest-start'), {
      target: { value: '2026-09-01' },
    })
    fireEvent.change(screen.getByTestId('register-harvest-end'), {
      target: { value: '2026-09-30' },
    })
    fireEvent.change(screen.getByTestId('register-harvest-kg'), { target: { value: '4100' } })
    submit()

    await waitFor(() => expect(rpc).toHaveBeenCalledTimes(1))
    expect(rpc.mock.calls[0][0]).toBe('app_register_farmer')
  })

  // The draft id IS the RPC's client_ref, so a retry after a timeout replays
  // rather than creating a second farmer.
  test('sends the draft id as its client_ref', async () => {
    renderScreen()
    await fillValid()
    submit()

    await waitFor(() => expect(rpc).toHaveBeenCalledTimes(1))
    const payload = rpc.mock.calls[0][1].payload as { client_ref: string; village_id: string }
    expect(payload.client_ref).toBe('draft-ref-1')
    expect(payload.village_id).toBe(VILLAGE)
  })

  test('clears the draft only after the RPC returned', async () => {
    renderScreen()
    await fillValid()
    submit()

    await waitFor(() => expect(clear).toHaveBeenCalledTimes(1))
  })
})

/**
 * QA #23. Measured directly at the time: `register-submit.disabled` was false
 * immediately after the first click and still false after three clicks in the
 * same tick. Spec 5.2 names six states for this screen and one of them is
 * SAVING — there was no saving state at all.
 *
 * `submit.isPending` alone cannot cover it: react-hook-form validates
 * asynchronously, so the mutation has not started yet on the tick the officer
 * clicks again.
 */
describe('the saving state spec 5.2 asks for', () => {
  test('three submits in the same tick register one farmer', async () => {
    // A write that never settles, which is what a slow rural connection looks
    // like from the officer's side.
    rpc.mockImplementation(() => new Promise(() => {}))
    renderScreen()
    await fillValid()

    submit()
    submit()
    submit()

    await waitFor(() => expect(rpc).toHaveBeenCalledTimes(1))
    expect(rpc).toHaveBeenCalledTimes(1)
  })

  test('and the control says what is happening rather than nothing', async () => {
    rpc.mockImplementation(() => new Promise(() => {}))
    renderScreen()
    await fillValid()
    submit()

    await waitFor(() => expect(screen.getByTestId('register-submit')).toBeDisabled())
    expect(screen.getByTestId('register-submit')).toHaveTextContent(/registering/i)
  })

  // A refused form is not a saving form: the officer has to be able to fix it
  // and submit again.
  test('a form that failed validation is submittable again', async () => {
    renderScreen()
    await fillValid()
    fireEvent.change(screen.getByTestId('register-given-name'), { target: { value: '   ' } })
    submit()

    await waitFor(() =>
      expect(screen.getByTestId('register-given-name-error')).toBeInTheDocument(),
    )
    expect(screen.getByTestId('register-submit')).toBeEnabled()
  })
})

/**
 * QA #22, at the screen. The corrupt draft restored verbatim, the badge said
 * "not yet submitted", and the form would have sent `[object Object]` as a
 * farmer's first name.
 */
describe('a draft that no longer matches this form', () => {
  /**
   * `useDraft` is what discards it — see useDraft.test.ts. What the SCREEN
   * owes is the other half: a discarded draft leaves an empty form and no
   * badge claiming there is unsaved work to come back to.
   */
  test('leaves an empty form and no unsaved badge', async () => {
    useDraft.mockReturnValue({ status: 'empty', draft: undefined, save, clear })
    renderScreen()

    await waitFor(() => expect(screen.getByTestId('register-given-name')).toHaveValue(''))
    expect(screen.getByTestId('register-family-name')).toHaveValue('')
    expect(screen.queryByTestId('unsaved-draft-badge')).not.toBeInTheDocument()
  })

  test('and the draft store is told to check the shape', () => {
    renderScreen()
    // The guard is passed to useDraft, which is what discards and clears it.
    expect(useDraftArgs.at(-1)?.[2]).toBe(isRegisterDraft)
  })

  // A good draft still restores: the point is the feature, not the check.
  test('a draft that does match is still restored', async () => {
    useDraft.mockReturnValue({
      status: 'dirty',
      draft: { ...EMPTY_DRAFT, given_name: 'Neema', family_name: 'Mwakalinga' },
      save,
      clear,
    })
    renderScreen()

    await waitFor(() => expect(screen.getByTestId('register-given-name')).toHaveValue('Neema'))
  })
})

/**
 * The unsaved-draft badge is required by business-rules.md §12 and asserted
 * by Playwright via its testid — it can move, but it must still exist, and
 * exactly once. Two copies (a header pill plus a footer echo) was the bug
 * being fixed here.
 */
describe('the unsaved-draft badge', () => {
  test('appears once, in the submit bar, when the draft is dirty', async () => {
    useDraft.mockReturnValue({
      status: 'dirty',
      draft: { ...EMPTY_DRAFT, given_name: 'Neema' },
      save,
      clear,
    })
    renderScreen()

    await waitFor(() => expect(screen.getByTestId('register-given-name')).toHaveValue('Neema'))
    expect(screen.getAllByTestId('unsaved-draft-badge')).toHaveLength(1)
    expect(
      screen.getByTestId('register-submit-bar').querySelector('[data-testid="unsaved-draft-badge"]'),
    ).not.toBeNull()
  })

  test('is absent when the draft is clean', async () => {
    useDraft.mockReturnValue({ status: 'clean', draft: null, save, clear })
    renderScreen()

    expect(screen.queryByTestId('unsaved-draft-badge')).not.toBeInTheDocument()
  })
})

/**
 * A section's card gets a soft green border once its own fields are filled —
 * the same completion the progress rail already computes, just reflected on
 * the card too (business-rules §22 territory: a hint, not a validation claim).
 */
describe('a completed section card', () => {
  test('is marked complete once its required fields are filled', async () => {
    renderScreen()

    const person = screen.getByRole('group', { name: /Person/ })
    expect(person).toHaveAttribute('data-complete', 'no')

    fireEvent.change(screen.getByTestId('register-given-name'), { target: { value: 'Neema' } })
    fireEvent.change(screen.getByTestId('register-family-name'), { target: { value: 'Mwakalinga' } })

    await waitFor(() => expect(person).toHaveAttribute('data-complete', 'yes'))
  })
})

/**
 * The Farm section's GPS auto-capture: `docs/screens-and-components.md`'s
 * `GpsCapture` states, wired into this screen's own coordinate fields rather
 * than a separate component.
 */
describe('farm GPS auto-capture', () => {
  afterEach(() => {
    Reflect.deleteProperty(navigator, 'geolocation')
  })

  function mockGeolocation() {
    const getCurrentPosition = vi.fn()
    Object.defineProperty(navigator, 'geolocation', {
      value: { getCurrentPosition },
      configurable: true,
    })
    return getCurrentPosition
  }

  test('an unsupported browser leaves the fields enabled, with an explanatory note and no retry button', async () => {
    Reflect.deleteProperty(navigator, 'geolocation')
    renderScreen()

    await screen.findByTestId('register-gps-status')
    expect(screen.getByTestId('register-gps-status')).toHaveTextContent(
      /can't detect location/i,
    )
    expect(screen.queryByTestId('register-gps-retry')).not.toBeInTheDocument()
    expect(screen.getByTestId('register-farm-latitude')).toBeEnabled()
    expect(screen.getByTestId('register-farm-longitude')).toBeEnabled()
  })

  test('a successful read fills and disables both coordinate fields', async () => {
    const getCurrentPosition = mockGeolocation()
    renderScreen()

    await waitFor(() => expect(getCurrentPosition).toHaveBeenCalledTimes(1))
    const [success] = getCurrentPosition.mock.calls[0]
    act(() => success({ coords: { latitude: -7.1, longitude: 34.9 } }))

    await waitFor(() => expect(screen.getByTestId('register-farm-latitude')).toHaveValue('-7.100000'))
    expect(screen.getByTestId('register-farm-longitude')).toHaveValue('34.900000')
    expect(screen.getByTestId('register-farm-latitude')).toBeDisabled()
    expect(screen.getByTestId('register-farm-longitude')).toBeDisabled()
  })

  test('a denied read shows why and offers a retry, which can then succeed', async () => {
    const getCurrentPosition = mockGeolocation()
    renderScreen()

    await waitFor(() => expect(getCurrentPosition).toHaveBeenCalledTimes(1))
    const [, failure] = getCurrentPosition.mock.calls[0]
    act(() => failure({ code: 1 }))

    await screen.findByTestId('register-gps-retry')
    expect(screen.getByTestId('register-gps-status')).toHaveTextContent(/declined/i)
    expect(screen.getByTestId('register-farm-latitude')).toBeEnabled()

    await userEvent.click(screen.getByTestId('register-gps-retry'))
    await waitFor(() => expect(getCurrentPosition).toHaveBeenCalledTimes(2))
    const [secondSuccess] = getCurrentPosition.mock.calls[1]
    act(() => secondSuccess({ coords: { latitude: 1, longitude: 2 } }))

    await waitFor(() => expect(screen.getByTestId('register-farm-latitude')).toHaveValue('1.000000'))
    expect(screen.getByTestId('register-farm-latitude')).toBeDisabled()
  })

  // The reload-survives-a-draft guarantee: a value already in the draft is the
  // officer's, typed or previously captured, and a fresh sensor read must not
  // silently replace it.
  test('a restored draft with its own coordinates is never overwritten by a GPS read', async () => {
    const getCurrentPosition = mockGeolocation()
    useDraft.mockReturnValue({
      status: 'dirty',
      draft: { ...EMPTY_DRAFT, farm_latitude: '-6.5', farm_longitude: '35.5' },
      save,
      clear,
    })
    renderScreen()

    await waitFor(() => expect(screen.getByTestId('register-farm-latitude')).toHaveValue('-6.5'))
    expect(screen.getByTestId('register-farm-longitude')).toHaveValue('35.5')
    expect(screen.getByTestId('register-farm-latitude')).toBeEnabled()
    expect(getCurrentPosition).not.toHaveBeenCalled()
  })
})
