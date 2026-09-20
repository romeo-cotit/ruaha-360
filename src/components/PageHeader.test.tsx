import { render, screen } from '@testing-library/react'
import { describe, expect, test, vi } from 'vitest'

import { PageHeader } from '@/components/PageHeader'

vi.mock('@tanstack/react-router', () => ({
  Link: ({ children, to, search, ...props }: { children: React.ReactNode; to?: string; search?: unknown } & Record<string, unknown>) => (
    <a href={to ?? '#'} data-search={search ? JSON.stringify(search) : undefined} {...props}>{children}</a>
  ),
}))

describe('PageHeader', () => {
  test('renders title, description, actions, breadcrumbs, and a logical parent link', () => {
    render(
      <PageHeader
        eyebrow="Ilundo · Production"
        title="Production by crop and window"
        description="Read the records behind this figure."
        backTo="/ops/tower"
        backLabel="Back to the Tower"
        backSearch={{ village: 'v1' }}
        breadcrumbs={[{ label: 'Control Tower', to: '/ops/tower' }, { label: 'Production' }]}
        actions={<button type="button">Export</button>}
      />,
    )

    expect(screen.getByRole('heading', { name: 'Production by crop and window' })).toBeInTheDocument()
    expect(screen.getByText('Read the records behind this figure.')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Export' })).toBeInTheDocument()
    expect(screen.getByTestId('page-header-actions')).toHaveClass('w-full', 'md:w-auto')
    expect(screen.getByRole('link', { name: /Back to the Tower/ })).toHaveAttribute('href', '/ops/tower')
    expect(screen.getByRole('link', { name: 'Control Tower' })).toHaveAttribute('href', '/ops/tower')
    expect(screen.getByText('Production').closest('li')).toHaveAttribute('aria-current', 'page')
  })

  test('does not add navigation chrome on a top-level page', () => {
    render(<PageHeader title="Request pipeline" />)

    expect(screen.getByRole('heading', { name: 'Request pipeline' })).toBeInTheDocument()
    expect(screen.queryByRole('navigation', { name: 'Breadcrumb' })).not.toBeInTheDocument()
    expect(screen.queryByRole('link', { name: /Back/ })).not.toBeInTheDocument()
  })

  test('stacks navigation and actions for a phone-sized viewport', () => {
    render(
      <PageHeader
        title="Buyer demand"
        backTo="/ops"
        breadcrumbs={[{ label: 'Operations', to: '/ops' }, { label: 'Buyer demand' }]}
        actions={<button type="button">Create demand</button>}
      />,
    )

    expect(screen.getByTestId('page-header')).toHaveClass('min-w-0')
    expect(screen.getByTestId('page-header-actions')).toHaveClass('w-full', 'flex-col')
    expect(screen.getByRole('listitem', { current: 'page' })).toHaveTextContent('Buyer demand')
  })
})
