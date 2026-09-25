import { beforeEach, describe, expect, test, vi } from 'vitest'

const maybeSingle = vi.fn()
const eq = vi.fn(() => ({ maybeSingle }))
const select = vi.fn(() => ({ eq }))
const from = vi.fn((_table: string) => ({ select }))
vi.mock('@/lib/supabase', () => ({ supabase: { from: (table: string) => from(table) } }))

const { recoverInsert } = await import('@/lib/recoverInsert')

const ID = '11111111-1111-4111-8111-111111111111'

beforeEach(() => {
  maybeSingle.mockReset()
  from.mockClear()
  eq.mockClear()
})

describe('recoverInsert', () => {
  // A timeout can arrive after the row committed. The retry reuses the
  // clientRef, so a duplicate-key answer means the first attempt landed.
  test('a row that already exists under this id is the success', async () => {
    maybeSingle.mockResolvedValue({ data: { id: ID }, error: null })
    await expect(recoverInsert('buyer', ID, { message: 'Failed to fetch' })).resolves.toEqual({ id: ID })
    expect(from).toHaveBeenCalledWith('buyer')
    expect(eq).toHaveBeenCalledWith('id', ID)
  })

  test('no row means the original error stands, verbatim', async () => {
    maybeSingle.mockResolvedValue({ data: null, error: null })
    await expect(recoverInsert('pue_request', ID, { message: 'illegal transition' })).rejects.toThrow('illegal transition')
  })

  test('a failed lookup never turns into a success', async () => {
    maybeSingle.mockResolvedValue({ data: null, error: { message: 'offline' } })
    await expect(recoverInsert('buyer_demand', ID, { message: 'Failed to fetch' })).rejects.toThrow('Failed to fetch')
  })

  test('without an id nothing is looked up', async () => {
    await expect(recoverInsert('opportunity_supply', undefined, { message: 'x' })).rejects.toThrow('x')
    expect(from).not.toHaveBeenCalled()
  })
})
