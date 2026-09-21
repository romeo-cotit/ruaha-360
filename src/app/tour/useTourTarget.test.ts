import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest'

import { useTourTarget } from '@/app/tour/useTourTarget'

const SELECTOR = '[data-testid="target"]'
const visible = new DOMRect(20, 100, 200, 48)
const offscreen = new DOMRect(20, 2_000, 200, 48)
let scrollTo = vi.fn()

const settle = () =>
  act(async () => {
    await Promise.resolve()
    await Promise.resolve()
  })

function addTarget(rect: DOMRect = visible) {
  const target = document.createElement('div')
  target.dataset.testid = 'target'
  target.getBoundingClientRect = vi.fn(() => rect)
  target.scrollIntoView = vi.fn()
  document.body.append(target)
  return target
}

describe('preparing a tour target', () => {
  beforeEach(() => {
    document.body.innerHTML = ''
    Object.defineProperty(window, 'scrollY', { configurable: true, value: 0, writable: true })
    Object.defineProperty(Element.prototype, 'scrollIntoView', {
      configurable: true,
      value: vi.fn(),
      writable: true,
    })
    scrollTo = vi.fn()
    Object.defineProperty(window, 'scrollTo', { configurable: true, value: scrollTo, writable: true })
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  test('instant-scrolls an existing target before declaring it ready', async () => {
    const target = addTarget()
    const onMissing = vi.fn()
    const { result } = renderHook(() =>
      useTourTarget('officer:3', SELECTOR, true, onMissing, 10_000),
    )

    expect(result.current).toBe(false)
    await settle()

    expect(target.scrollIntoView).toHaveBeenCalledWith({
      behavior: 'auto',
      block: 'center',
      inline: 'nearest',
    })
    expect(scrollTo).toHaveBeenCalled()
    expect(result.current).toBe(true)
    expect(onMissing).not.toHaveBeenCalled()
  })

  test('waits for route content that mounts later', async () => {
    const onMissing = vi.fn()
    const { result } = renderHook(() =>
      useTourTarget('ops:2', SELECTOR, true, onMissing, 10_000),
    )
    await settle()
    expect(result.current).toBe(false)

    const target = addTarget()
    await settle()

    expect(target.scrollIntoView).toHaveBeenCalledOnce()
    expect(result.current).toBe(true)
  })

  test('does not prepare an old route target', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    const target = addTarget()
    const onMissing = vi.fn()
    renderHook(() => useTourTarget('farmer:4', SELECTOR, false, onMissing, 10_000))
    await settle()

    expect(target.scrollIntoView).not.toHaveBeenCalled()

    await act(async () => {
      vi.advanceTimersByTime(10_000)
      await Promise.resolve()
    })
    expect(onMissing).toHaveBeenCalledOnce()
  })

  test('closes safely when scrolling cannot bring the target into view', async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true })
    addTarget(offscreen)
    const onMissing = vi.fn()
    const { result } = renderHook(() =>
      useTourTarget('officer:3', SELECTOR, true, onMissing, 10_000),
    )
    await settle()

    expect(result.current).toBe(false)
    await act(async () => {
      vi.advanceTimersByTime(10_000)
      await Promise.resolve()
    })

    expect(onMissing).toHaveBeenCalledOnce()
    expect(result.current).toBe(false)
  })

  test('uses an explicit document scroll when element scrolling does not move WebKit', async () => {
    const target = addTarget()
    target.getBoundingClientRect = vi.fn(() =>
      window.scrollY === 0 ? new DOMRect(20, 2_000, 200, 48) : visible,
    )
    scrollTo.mockImplementation(({ top }: ScrollToOptions) => {
      Object.defineProperty(window, 'scrollY', { configurable: true, value: top ?? 0, writable: true })
    })

    const { result } = renderHook(() =>
      useTourTarget('officer:3', SELECTOR, true, vi.fn(), 10_000),
    )
    await settle()

    expect(target.scrollIntoView).toHaveBeenCalledOnce()
    expect(scrollTo).toHaveBeenCalledWith({ top: expect.any(Number), behavior: 'auto' })
    expect(result.current).toBe(true)
  })

  test('a new step is unready until its own target is positioned', async () => {
    const first = addTarget()
    const onMissing = vi.fn()
    const view = renderHook(
      ({ targetKey, selector }: { targetKey: string; selector: string }) =>
        useTourTarget(targetKey, selector, true, onMissing, 10_000),
      { initialProps: { targetKey: 'officer:2', selector: SELECTOR } },
    )
    await settle()
    expect(view.result.current).toBe(true)

    first.remove()
    view.rerender({ targetKey: 'officer:3', selector: '[data-testid="next-target"]' })
    expect(view.result.current).toBe(false)

    const next = document.createElement('div')
    next.dataset.testid = 'next-target'
    next.getBoundingClientRect = vi.fn(() => visible)
    next.scrollIntoView = vi.fn()
    document.body.append(next)
    await settle()

    expect(next.scrollIntoView).toHaveBeenCalledOnce()
    expect(view.result.current).toBe(true)
  })
})
