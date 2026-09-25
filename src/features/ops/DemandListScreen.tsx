import { useMemo, useRef, useState } from 'react'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { ChevronDown, ChevronUp } from 'lucide-react'
import { useNavigate } from '@tanstack/react-router'
import { createColumnHelper } from '@tanstack/react-table'
import { useTranslation } from 'react-i18next'

import { DataTable } from '@/components/DataTable'
import { ErrorState } from '@/components/ErrorState'
import { CONTROL } from '@/components/controlStyles'
import { IndicativePill, Loading } from '@/components/controls'
import { BangMark } from '@/components/marks'
import { PageHeader } from '@/components/PageHeader'
import { StatusPill } from '@/components/StatusPill'
import { TableSurface } from '@/components/TableSurface'
import { Button } from '@/components/ui/button'
import { FormDraftStatus } from '@/components/FormDraftStatus'
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select'
import {
  useCreateDemand,
  useDemandFormOptions,
  useDemands,
  type Demand,
} from '@/features/ops/useDemand'
import { formatKg, formatMoney, formatPlainDate } from '@/lib/format'
import { usePersistentForm } from '@/lib/usePersistentForm'
import { useSession } from '@/app/session'

/** Spec 7.6 — the order book, plus a create form. */
export function DemandListScreen() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const query = useDemands()
  const options = useDemandFormOptions()
  const create = useCreateDemand()
  const session = useSession()
  const projectScope = session.data?.memberships.find(m => m.role === 'ops' || m.role === 'admin')?.project_id ?? 'project'
  const draft = usePersistentForm('demand-create', projectScope, DEMAND_DEFAULTS, zodResolver(demandSchema))

  const [buyerId, setBuyerId] = draft.field('buyerId')
  const [cropId, setCropId] = draft.field('cropId')
  const [quantity, setQuantity] = draft.field('quantity')
  const [windowStart, setWindowStart] = draft.field('windowStart')
  const [windowEnd, setWindowEnd] = draft.field('windowEnd')
  const [deliveryPoint, setDeliveryPoint] = draft.field('deliveryPoint')
  const [pricePerKg, setPricePerKg] = draft.field('pricePerKg')
  const [qualityNote, setQualityNote] = draft.field('qualityNote')
  const [touched, setTouched] = useState(false)
  const [createOpen, setCreateOpen] = useState(false)
  /**
   * QA #23. `isPending` only becomes true on the NEXT render, so Enter and a
   * click arriving in one tick both passed the disabled check. A ref latches
   * synchronously and is released when the write settles.
   */
  const inFlight = useRef(false)

  const columns = useMemo(() => {
    const col = createColumnHelper<Demand>()
    return [
      col.accessor('buyer_name', { header: t('demand.colBuyer') }),
      col.accessor('crop_name', { header: t('demand.colCrop') }),
      col.accessor('quantity_kg', {
        header: t('demand.colQuantity'),
        meta: { numeric: true },
        cell: (c) => formatKg(c.getValue()),
      }),
      col.accessor((r) => `${r.window_start}|${r.window_end}`, {
        id: 'window',
        header: t('demand.colWindow'),
        cell: (c) => {
          const [start, end] = String(c.getValue()).split('|')
          return `${formatPlainDate(start)} – ${formatPlainDate(end)}`
        },
      }),
      col.accessor('indicative_price_per_kg', {
        header: t('demand.colPrice'),
        meta: { numeric: true },
        // Prices are indicative, never quotations — and the tag travels with
        // the number rather than trailing it in a parenthesis.
        cell: (c) => (
          <span className="inline-flex flex-wrap items-baseline justify-end gap-2">
            <span className="tabular font-semibold">
              {formatMoney(c.getValue(), c.row.original.currency)}
            </span>
            <IndicativePill />
          </span>
        ),
      }),
      col.accessor('quality_note', {
        header: t('demand.qualityNote'),
        cell: (c) => c.getValue() ?? '—',
      }),
      col.accessor('status', {
        header: t('demand.colStatus'),
        cell: (c) => <StatusPill kind="demand" status={c.getValue()} />,
      }),
    ]
  }, [t])

  if (query.error) return <ErrorState error={query.error} onRetry={() => void query.refetch()} />

  const projectId = options.data?.buyers.find((b) => b.id === buyerId)?.project_id
  const missing = {
    buyer: touched && buyerId === '',
    crop: touched && cropId === '',
    quantity: touched && (quantity === '' || Number(quantity) <= 0),
  }

  const submit = () => {
    if (inFlight.current || create.isPending || !draft.ready) return
    setTouched(true)
    if (buyerId === '' || cropId === '' || quantity === '' || Number(quantity) <= 0) return
    if (!projectId) return

    inFlight.current = true
    create.mutate(
      {
        id: draft.clientRef,
        projectId,
        buyerId,
        cropId,
        quantityKg: Number(quantity),
        windowStart,
        windowEnd,
        deliveryPoint,
        pricePerKg,
        qualityNote,
      },
      { onSuccess: () => void draft.finish(), onSettled: () => (inFlight.current = false) },
    )
  }

  return (
    <section className="flex flex-col gap-5">
      <PageHeader
        title={t('demand.title')}
        actions={
          <Button
            type="button"
            data-testid="demand-create-open"
            aria-expanded={createOpen}
            aria-controls="demand-create-panel"
            variant={createOpen ? 'secondary' : 'primary'}
            onClick={() => setCreateOpen((open) => !open)}
          >
            {createOpen ? t('common.close') : t('demand.create')}
            {createOpen ? <ChevronUp aria-hidden size={16} /> : <ChevronDown aria-hidden size={16} />}
          </Button>
        }
      />

      {createOpen && (
        <section
          id="demand-create-panel"
          data-testid="demand-create-panel"
          className="flex w-full flex-col gap-3 p-4 sm:p-[18px]"
          style={{
            border: '1px solid var(--rule)',
            borderRadius: 'var(--radius-card)',
            background: 'var(--paper)',
          }}
        >
          <div className="flex flex-wrap items-center justify-between gap-2">
            <h2 className="type-section" style={{ color: 'var(--ink-3)' }}>
              {t('demand.createTitle')}
            </h2>
            <Button
              type="button"
              data-testid="demand-create-close"
              variant="ghost"
              size="sm"
              onClick={() => setCreateOpen(false)}
            >
              {t('common.close')}
            </Button>
          </div>

          {/* A real form: eight fields typed then submitted, so Enter has to
              work and a keyboard user must not have to tab past all of them to
              reach the control. QA #11. */}
          <form
            className="flex flex-col gap-3"
            noValidate
            onSubmit={(e) => {
              e.preventDefault()
              submit()
            }}
          >
        <FormDraftStatus dirty={draft.dirty} storageError={draft.storageError} />
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <Field label={t('demand.buyer')} id="demand-buyer" error={missing.buyer ? t('demand.required') : undefined} errorTestId="demand-buyer-error">
            <Select value={buyerId} onValueChange={(value) => setBuyerId(value ?? '')}>
              <SelectTrigger id="demand-buyer" data-testid="demand-buyer" className={input}>
                {options.data?.buyers.find((buyer) => buyer.id === buyerId)?.name ?? t('demand.chooseBuyer')}
              </SelectTrigger>
              <SelectContent>
              {(options.data?.buyers ?? []).map((b) => (
                <SelectItem key={b.id} value={b.id}>{b.name}</SelectItem>
              ))}
              </SelectContent>
            </Select>
          </Field>

          <Field label={t('demand.crop')} id="demand-crop" error={missing.crop ? t('demand.required') : undefined} errorTestId="demand-crop-error">
            <Select value={cropId} onValueChange={(value) => setCropId(value ?? '')}>
              <SelectTrigger id="demand-crop" data-testid="demand-crop" className={input}>
                {options.data?.crops.find((crop) => crop.id === cropId)?.name ?? t('demand.chooseCrop')}
              </SelectTrigger>
              <SelectContent>
              {(options.data?.crops ?? []).map((c) => (
                <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
              ))}
              </SelectContent>
            </Select>
          </Field>

          <Field label={t('demand.quantity')} id="demand-quantity" error={missing.quantity ? t('demand.required') : undefined} errorTestId="demand-quantity-error">
            <input id="demand-quantity" data-testid="demand-quantity" inputMode="decimal" value={quantity} onChange={(e) => setQuantity(e.target.value)} className={input} style={CONTROL} />
          </Field>

          <Field label={t('demand.pricePerKg')} id="demand-price">
            <input id="demand-price" data-testid="demand-price" inputMode="decimal" value={pricePerKg} onChange={(e) => setPricePerKg(e.target.value)} className={input} style={CONTROL} />
          </Field>

          <Field label={t('demand.windowStart')} id="demand-window-start">
            <input id="demand-window-start" data-testid="demand-window-start" type="date" value={windowStart} onChange={(e) => setWindowStart(e.target.value)} className={input} style={CONTROL} />
          </Field>

          <Field label={t('demand.windowEnd')} id="demand-window-end">
            <input id="demand-window-end" data-testid="demand-window-end" type="date" value={windowEnd} onChange={(e) => setWindowEnd(e.target.value)} className={input} style={CONTROL} />
          </Field>

          <Field label={t('demand.deliveryPoint')} id="demand-delivery">
            <input id="demand-delivery" data-testid="demand-delivery" value={deliveryPoint} onChange={(e) => setDeliveryPoint(e.target.value)} className={input} style={CONTROL} />
          </Field>

          <Field label={t('demand.qualityNote')} id="demand-quality-note">
            <input id="demand-quality-note" data-testid="demand-quality-note" value={qualityNote} onChange={(e) => setQualityNote(e.target.value)} className={input} style={CONTROL} />
          </Field>
        </div>

        {create.isError && (
          <div data-testid="demand-create-error">
            <ErrorState error={create.error} onRetry={() => create.reset()} />
          </div>
        )}

            <Button
              type="submit"
              data-testid="demand-create-submit"
              disabled={!draft.ready || create.isPending}
              className="w-fit"
            >
              {create.isPending ? t('demand.creating') : t('demand.create')}
            </Button>
          </form>
        </section>
      )}

      {query.isLoading ? (
        <Loading testId="demand-loading" />
      ) : (
        <TableSurface>
          <DataTable
            columns={columns}
            data={query.demands}
            testId="demand-table"
            rowTestId="demand-row"
            onRowClick={(row) => void navigate({ to: '/ops/demand/$demandId', params: { demandId: row.id } })}
            empty={{ title: t('demand.noneTitle'), detail: t('demand.noneDetail') }}
          />
        </TableSurface>
      )}
    </section>
  )
}

const demandSchema = z.object({
  buyerId: z.string(), cropId: z.string(), quantity: z.string(), windowStart: z.string(),
  windowEnd: z.string(), deliveryPoint: z.string(), pricePerKg: z.string(), qualityNote: z.string(),
})
const DEMAND_DEFAULTS = {
  buyerId: '', cropId: '', quantity: '', windowStart: '', windowEnd: '',
  deliveryPoint: '', pricePerKg: '', qualityNote: '',
}

const input = 'w-full'

function Field({
  label,
  id,
  error,
  errorTestId,
  children,
}: {
  label: string
  id: string
  error?: string
  errorTestId?: string
  children: React.ReactNode
}) {
  return (
    <div className="flex min-w-0 flex-col gap-1.5">
      <label
        className="block"
        htmlFor={id}
        style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink-2)' }}
      >
        {label}
      </label>
      {children}
      {error && (
        <p
          data-testid={errorTestId}
          className="flex items-start gap-[7px] font-medium"
          style={{ fontSize: 13, color: 'var(--flag-ink)' }}
        >
          <BangMark />
          {error}
        </p>
      )}
    </div>
  )
}
