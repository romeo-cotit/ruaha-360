import { useEffect, useRef, useState } from 'react'

import { isVisibleInViewport } from '@/app/tour/tourVisibility'

/**
 * Prepare one tour target before Joyride is allowed to mount its overlay.
 *
 * Joyride's own animated scroll is disabled because it has stalled in a
 * production build. This hook keeps that workaround, waits for route content
 * to exist, and performs a synchronous browser scroll instead. The keyed
 * result makes a new step read as unready immediately, without an effect that
 * first has to reset stale state from the previous stop.
 */
export function useTourTarget(
  targetKey: string | null,
  selector: string | null,
  routeReady: boolean,
  onMissing: () => void,
  timeoutMs = 10_000,
): boolean {
  const [readyKey, setReadyKey] = useState<string | null>(null)
  const missing = useRef(onMissing)

  useEffect(() => {
    missing.current = onMissing
  }, [onMissing])

  useEffect(() => {
    if (!targetKey || !selector) return

    let done = false
    let prepared: Element | null = null

    const visualViewport = window.visualViewport

    const clean = () => {
      observer.disconnect()
      clearTimeout(timer)
      window.removeEventListener('scroll', verify, true)
      window.removeEventListener('resize', verify)
      visualViewport?.removeEventListener('scroll', verify)
      visualViewport?.removeEventListener('resize', verify)
    }

    const finish = () => {
      if (done) return
      done = true
      clean()
      setReadyKey(targetKey)
    }

    function verify() {
      if (!done && isVisibleInViewport(prepared)) finish()
    }

    const prepare = () => {
      if (done || !routeReady) return

      const target = document.querySelector(selector)
      if (!target) return

      if (target !== prepared) {
        prepared = target
        target.scrollIntoView({ behavior: 'auto', block: 'center', inline: 'nearest' })
      }

      // The automatic scroll is synchronous, but defer the geometry read until
      // the browser has applied the resulting layout and sticky positioning.
      queueMicrotask(verify)
    }

    const observer = new MutationObserver(prepare)
    observer.observe(document.body, { childList: true, subtree: true })
    window.addEventListener('scroll', verify, true)
    window.addEventListener('resize', verify)
    visualViewport?.addEventListener('scroll', verify)
    visualViewport?.addEventListener('resize', verify)

    const timer = setTimeout(() => {
      if (done) return
      done = true
      clean()
      missing.current()
    }, timeoutMs)

    queueMicrotask(prepare)

    return () => {
      done = true
      clean()
    }
  }, [routeReady, selector, targetKey, timeoutMs])

  return targetKey !== null && readyKey === targetKey
}
