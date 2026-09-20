import type { Page } from '@playwright/test'

/** Open a Base UI/shadcn Select and choose by its stable value or visible label. */
export async function chooseSelect(page: Page, testId: string, valueOrLabel: string) {
  await page.getByTestId(testId).click()
  const byValue = page.locator(`[role="option"][data-value="${valueOrLabel}"]`)
  if (await byValue.count()) {
    await byValue.first().click()
    return
  }
  await page.getByRole('option').filter({ hasText: valueOrLabel }).first().click()
}
