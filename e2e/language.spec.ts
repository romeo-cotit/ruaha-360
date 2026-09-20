import { expect, test } from '@playwright/test'
import { chooseSelect } from './support/select'

/**
 * Spec 4.1: "Language switch, persisted to app_user.locale."
 *
 * app_user.locale is the source of truth, not localStorage — the choice has to
 * follow the user to the next device. The seed gives the officers and farmers
 * locale 'sw' and the ops/admin accounts 'en', so the applied locale is
 * observable straight after sign-in.
 *
 * Note these tests assert the SELECTED LOCALE, not translated copy. Swahili
 * product strings do not exist yet (CLAUDE.md requires a native reviewer), so
 * sw currently falls back to English text by design.
 */
const PASSWORD = 'demo1234'

async function signIn(page: import('@playwright/test').Page, email: string) {
  await page.goto('/login')
  await page.getByTestId('login-email').fill(email)
  await page.getByTestId('login-password').fill(PASSWORD)
  await page.getByTestId('login-submit').click()
}

test('the session applies app_user.locale on sign-in', async ({ page }) => {
  // Salima Officer is seeded with locale 'sw'.
  await signIn(page, 'officer.ilundo@demo.ruaha360.test')
  await expect(page).toHaveURL(/\/officer$/)

  await expect(page.getByTestId('language-switch')).toContainText('Kiswahili')
})

test('an account seeded as English stays English', async ({ page }) => {
  // Asha Ops is seeded with locale 'en'.
  await signIn(page, 'ops@demo.ruaha360.test')
  await expect(page).toHaveURL(/\/ops$/)

  await expect(page.getByTestId('language-switch')).toContainText('English')
})

test('a language change survives a reload, because it is stored on app_user', async ({ page }) => {
  await signIn(page, 'officer.ilundo@demo.ruaha360.test')
  await expect(page).toHaveURL(/\/officer$/)
  await expect(page.getByTestId('language-switch')).toContainText('Kiswahili')

  const select = page.getByTestId('language-switch')

  await chooseSelect(page, 'language-switch', 'Kiingereza')
  await expect(select).toContainText('English')
  // The switch disables itself while the write is in flight, so being enabled
  // again is the user-visible signal that it landed. No arbitrary waiting.
  await expect(select).toBeEnabled()

  await page.reload()
  await expect(select).toContainText('English')

  // Leave the seed as it was found, so the suite is re-runnable.
  await chooseSelect(page, 'language-switch', 'Kiswahili')
  await expect(select).toContainText('Kiswahili')
  await expect(select).toBeEnabled()
  await page.reload()
  await expect(select).toContainText('Kiswahili')
})
