/**
 * Whether an element is something a person can actually see in the viewport.
 *
 * DOM presence is not enough for a guided tour: a positioned tooltip can be
 * fully rendered thousands of pixels below the viewport while its overlay is
 * already swallowing every input. Walk the ancestor chain as well because
 * Joyride applies some of its transitional visibility to a wrapper around our
 * tooltip rather than to the tooltip itself.
 */
export function isVisibleInViewport(element: Element | null): element is Element {
  if (!element?.isConnected) return false

  let current: Element | null = element
  while (current) {
    const style = getComputedStyle(current)
    if (
      style.display === 'none' ||
      style.visibility === 'hidden' ||
      style.visibility === 'collapse' ||
      Number.parseFloat(style.opacity || '1') === 0
    ) {
      return false
    }
    current = current.parentElement
  }

  const rect = element.getBoundingClientRect()
  if (rect.width <= 0 || rect.height <= 0) return false

  const viewport = window.visualViewport
  const left = viewport?.offsetLeft ?? 0
  const top = viewport?.offsetTop ?? 0
  const width = viewport?.width || window.innerWidth || document.documentElement.clientWidth
  const height = viewport?.height || window.innerHeight || document.documentElement.clientHeight

  return rect.right > left && rect.left < left + width && rect.bottom > top && rect.top < top + height
}
