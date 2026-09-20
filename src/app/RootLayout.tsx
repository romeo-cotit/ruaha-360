import { Link, Outlet, useLocation } from '@tanstack/react-router'
import { useTranslation } from 'react-i18next'

import { BrandLockup } from '@/app/BrandLockup'
import { DemoBanner } from '@/app/DemoBanner'
import { LanguageSwitch } from '@/app/LanguageSwitch'
import { SignOutButton } from '@/app/SignOutButton'
import { SurfaceNav } from '@/app/SurfaceNav'
import { TourButton } from '@/app/tour/TourButton'
import { TourProvider } from '@/app/tour/TourProvider'
import { activeMemberships } from '@/app/membership'
import { navItemsFor, navLayoutForSurface, navSurfaceFor } from '@/app/nav'
import { useSession } from '@/app/session'

/**
 * App shell — spec 4.1.
 *
 * Role-aware nav: farmer and officer surfaces get a bottom tab bar and are
 * mobile-first; ops gets a sidebar and is desktop-first. The layout follows the
 * CURRENT surface rather than the role set, because a user may hold several
 * roles and the active one lives in the URL.
 *
 * The header carries the supplied Ruaha Energy lockup — 26px on ops, 23px on a
 * field surface, where the header has less room and more thumb — followed by a
 * hairline divider and `360`. A skip link precedes everything: the ops sidebar
 * is six destinations to tab past otherwise.
 */
export function RootLayout() {
  const { data: session } = useSession()
  const { pathname } = useLocation()
  const { t } = useTranslation()

  const memberships = activeMemberships(session?.memberships ?? [])
  // The surface whose nav to show — not always the surface of the path. An ops
  // user reading an officer record keeps the ops sidebar; see navSurfaceFor.
  const surface = navSurfaceFor(pathname, memberships)
  const layout = navLayoutForSurface(surface)
  const items = surface ? navItemsFor(surface, memberships) : []
  const signedIn = Boolean(session)

  return (
    <TourProvider surface={surface} userId={session?.appUser?.id}>
      <div className="flex min-h-dvh flex-col bg-sand font-sans text-ink">
        <a
          href="#main"
          className="sr-only rounded-[var(--radius-control)] bg-paper px-4 py-2 font-medium text-primary-ink focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50"
          style={{ border: '1.5px solid var(--primary)' }}
        >
          {t('a11y.skipToContent')}
        </a>

        {/* Always visible, driven by VITE_DATA_MODE and never by a column. */}
        <DemoBanner />

        <header
          data-testid="global-header"
          className="flex flex-wrap items-center justify-between gap-3.5 px-3 py-3 sm:px-4 lg:px-[18px]"
          style={{ background: 'var(--paper)', borderBottom: '1px solid var(--rule)' }}
        >
          <div className="mx-auto flex w-full max-w-screen-2xl flex-col items-stretch gap-3.5 sm:flex-row sm:items-center sm:justify-between">
            <Link to="/" className="self-start">
              <BrandLockup height={layout === 'tabs' ? 23 : 26} />
            </Link>

            <div
              data-testid="global-header-actions"
              className="grid w-full grid-cols-2 gap-2 sm:flex sm:w-auto sm:flex-wrap sm:items-center sm:justify-end [&>button]:w-full sm:[&>button]:w-auto [&>div]:w-full sm:[&>div]:w-auto"
            >
              {session?.appUser && (
                <span
                  data-testid="current-user"
                  className="col-span-2 inline-flex min-h-11 items-center rounded-full bg-sand-2 px-3 py-1.5 text-sm font-medium text-ink-2 sm:col-span-auto"
                >
                  {session.appUser.display_name}
                </span>
              )}
              {/* The tour crosses screens, so the way back to it belongs in the
                  header rather than on any one of them. */}
              {signedIn && <TourButton />}
              <LanguageSwitch className="w-full sm:w-auto" />
              {signedIn && <SignOutButton className="w-full sm:w-auto" />}
            </div>
          </div>
        </header>

        {/* Column below `lg`, so the ops sidebar becomes a strip above the
            content rather than squeezing it — QA #8. */}
        <div className="flex flex-1 flex-col lg:flex-row">
          {layout === 'sidebar' && <SurfaceNav layout={layout} items={items} />}

          {/*
            Bottom padding keeps the tab bar clear of the last row of content.
            The desktop padding is applied only where there IS no tab bar: a `lg:`
            variant beats `pb-20`, which at a desktop width left the 60px bar
            sitting on top of the register form's only submit button.
          */}
          <main
            id="main"
            className={
              layout === 'tabs'
                ? 'min-w-0 flex-1 overflow-x-hidden p-4 pb-24'
                : 'min-w-0 flex-1 p-4 lg:p-8 xl:p-10'
            }
          >
            <div className="mx-auto w-full min-w-0">
              <Outlet />
            </div>
          </main>
        </div>

        {layout === 'tabs' && <SurfaceNav layout={layout} items={items} />}
      </div>
    </TourProvider>
  )
}
