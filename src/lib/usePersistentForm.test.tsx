import { act, renderHook, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, test, vi } from 'vitest'

import { createMemoryDraftStore, type DraftStore } from '@/lib/drafts'

const session = { data: { userId: 'user-a' } as { userId: string } | undefined }
vi.mock('@/app/session', () => ({ useSession: () => session }))

const { usePersistentForm } = await import('@/lib/usePersistentForm')

const DEFAULTS = { name: '', note: '' }
const KEY_A = 'form:user-a:project-1:buyer-create'
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/

let store: DraftStore

beforeEach(() => {
  store = createMemoryDraftStore()
  session.data = { userId: 'user-a' }
})

function mount(scope = 'project-1', s: DraftStore = store) {
  return renderHook(({ scope }) => usePersistentForm('buyer-create', scope, DEFAULTS, undefined, s), {
    initialProps: { scope },
  })
}

describe('usePersistentForm', () => {
  test('is not ready until the stored draft has been read', async () => {
    let release: (() => void) | undefined
    const slow: DraftStore = {
      ...store,
      get: () => new Promise((resolve) => { release = () => resolve(undefined) }),
    }
    const { result } = mount('project-1', slow)
    expect(result.current.ready).toBe(false)
    // The read is queued per key; wait for it to start before releasing it,
    // or the queue stays blocked for every later test on this key.
    await waitFor(() => expect(release).toBeDefined())
    expect(result.current.ready).toBe(false)
    await act(async () => release!())
    await waitFor(() => expect(result.current.ready).toBe(true))
  })

  // A dialog can be typed into before IndexedDB answers. Those keystrokes are
  // the user's latest intent: kept, persisted, and never overwritten by the
  // restore that lands after them.
  test('typing before the restore finishes is kept, not overwritten', async () => {
    await store.set(KEY_A, { clientRef: '22222222-2222-4222-8222-222222222222', values: { name: 'Old draft', note: '' } })
    let release: (() => void) | undefined
    const slow: DraftStore = {
      ...store,
      get: (key) => new Promise((resolve) => { release = () => void store.get(key).then(resolve) }),
    }
    const { result } = mount('project-1', slow)
    await waitFor(() => expect(release).toBeDefined())
    try {
      act(() => result.current.field('name')[1]('Typed early'))
      expect(result.current.values.name).toBe('Typed early')
    } finally {
      // Always unblock the per-key queue, or every later test on it hangs.
      await act(async () => release!())
    }
    await waitFor(() => expect(result.current.ready).toBe(true))
    expect(result.current.values.name).toBe('Typed early')
    expect(result.current.dirty).toBe(true)
    // The restored clientRef is kept, so an uncertain earlier submit still reconciles.
    expect(result.current.clientRef).toBe('22222222-2222-4222-8222-222222222222')
    await waitFor(async () => expect(await store.get(KEY_A)).toMatchObject({ values: { name: 'Typed early' } }))
  })

  // A reload is a remount: the values and the clientRef both come back, so a
  // resubmit after an uncertain response reuses the same row id.
  test('restores values and clientRef after a reload', async () => {
    const first = mount()
    await waitFor(() => expect(first.result.current.ready).toBe(true))
    const clientRef = first.result.current.clientRef
    act(() => first.result.current.field('name')[1]('Mbeya Millers'))
    await waitFor(async () => expect(await store.get(KEY_A)).toEqual({ clientRef, values: { name: 'Mbeya Millers', note: '' } }))
    first.unmount()

    const second = mount()
    await waitFor(() => expect(second.result.current.ready).toBe(true))
    expect(second.result.current.values.name).toBe('Mbeya Millers')
    expect(second.result.current.clientRef).toBe(clientRef)
    expect(second.result.current.dirty).toBe(true)
  })

  test('a failed submit leaves the draft in place', async () => {
    const { result } = mount()
    await waitFor(() => expect(result.current.ready).toBe(true))
    act(() => result.current.field('name')[1]('Kept'))
    // Nothing calls finish() on failure; the stored draft is untouched.
    await waitFor(async () => expect(await store.get(KEY_A)).toMatchObject({ values: { name: 'Kept' } }))
    expect(result.current.dirty).toBe(true)
  })

  test('finish clears only after it is called, and issues a fresh clientRef', async () => {
    const { result } = mount()
    await waitFor(() => expect(result.current.ready).toBe(true))
    const before = result.current.clientRef
    act(() => result.current.field('name')[1]('Saved'))
    await act(async () => { await result.current.finish() })
    await expect(store.get(KEY_A)).resolves.toBeUndefined()
    expect(result.current.values.name).toBe('')
    expect(result.current.dirty).toBe(false)
    expect(result.current.clientRef).toMatch(UUID)
    expect(result.current.clientRef).not.toBe(before)
  })

  // Saves are serialised per key, so a write queued before finish() lands
  // before the clear and nothing resurrects the draft afterwards.
  test('a late save cannot resurrect a cleared draft', async () => {
    let releaseSet: (() => void) | undefined
    const gated: DraftStore = {
      get: store.get,
      clear: store.clear,
      set: (key, value) => new Promise<void>((resolve) => {
        releaseSet = () => void store.set(key, value).then(resolve)
      }),
    }
    const { result } = mount('project-1', gated)
    await waitFor(() => expect(result.current.ready).toBe(true))
    act(() => result.current.field('name')[1]('Late'))
    // The save is in flight when the server confirms and finish() runs.
    await waitFor(() => expect(releaseSet).toBeDefined())
    let finished!: Promise<void>
    act(() => { finished = result.current.finish() })
    // A keystroke after finish() began is dropped, not queued behind it.
    act(() => result.current.field('name')[1]('After'))
    await act(async () => { releaseSet!(); await finished })
    await expect(store.get(KEY_A)).resolves.toBeUndefined()
    expect(result.current.values.name).toBe('')
  })

  test('a storage failure is reported, and typing still works', async () => {
    const broken: DraftStore = {
      get: async () => undefined,
      set: async () => { throw new Error('quota') },
      clear: async () => undefined,
    }
    const { result } = mount('project-1', broken)
    await waitFor(() => expect(result.current.ready).toBe(true))
    act(() => result.current.field('name')[1]('Unsaved'))
    await waitFor(() => expect(result.current.storageError).toBe(true))
    expect(result.current.values.name).toBe('Unsaved')
  })

  test('an unreadable store is reported, and the form still opens', async () => {
    const broken: DraftStore = {
      get: async () => { throw new Error('blocked') },
      set: async () => undefined,
      clear: async () => undefined,
    }
    const { result } = mount('project-1', broken)
    await waitFor(() => expect(result.current.ready).toBe(true))
    expect(result.current.storageError).toBe(true)
    expect(result.current.values).toEqual(DEFAULTS)
  })

  test('a malformed stored draft is discarded, not restored', async () => {
    await store.set(KEY_A, { clientRef: 'not-a-uuid', values: { name: 42 } })
    const { result } = mount()
    await waitFor(() => expect(result.current.ready).toBe(true))
    expect(result.current.values).toEqual(DEFAULTS)
    await expect(store.get(KEY_A)).resolves.toBeUndefined()
  })

  // Drafts are keyed by the signed-in account: switching accounts on a
  // shared handset must not show the previous user's half-typed form.
  test('another account never sees the first account draft', async () => {
    const first = mount()
    await waitFor(() => expect(first.result.current.ready).toBe(true))
    act(() => first.result.current.field('name')[1]('Belongs to A'))
    await waitFor(async () => expect(await store.get(KEY_A)).toBeDefined())
    first.unmount()

    session.data = { userId: 'user-b' }
    const second = mount()
    await waitFor(() => expect(second.result.current.ready).toBe(true))
    expect(second.result.current.values).toEqual(DEFAULTS)
    await expect(store.get(KEY_A)).resolves.toMatchObject({ values: { name: 'Belongs to A' } })
  })

  test('a different record scope has its own draft', async () => {
    const { result, rerender } = mount('project-1')
    await waitFor(() => expect(result.current.ready).toBe(true))
    act(() => result.current.field('name')[1]('Scope one'))
    await waitFor(async () => expect(await store.get(KEY_A)).toBeDefined())

    rerender({ scope: 'project-2' })
    await waitFor(() => expect(result.current.ready).toBe(true))
    expect(result.current.values).toEqual(DEFAULTS)
  })
})
