import { useTranslation } from 'react-i18next'

import { useTour } from '@/app/tour/tourContext'
import { Button } from '@/components/ui/button'

/**
 * The way back to the tour.
 *
 * In the header rather than on a screen: the tours cross screens, and a control
 * that appears on only one of them is one nobody finds twice. Labelled rather
 * than an icon alone — the same rule the nav follows, for the same reason.
 */
export function TourButton() {
  const { t } = useTranslation()
  const { start, available } = useTour()

  if (!available) return null

  return (
    <Button
      data-testid="tour-restart"
      onClick={start}
      variant="secondary"
      size="default"
    >
      {t('tour.restart')}
    </Button>
  )
}
