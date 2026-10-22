import { useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { FormError, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import {
  canCancel,
  formatRupees,
  formatWhen,
  fulfilmentLabel,
  nextStatus,
  nextStatusLabel,
  paymentLabel,
  statusLabel,
  statusTone,
} from '../lib/format'
import type { Order, OrderStatus } from '../types'

const filters = [
  { id: 'all', label: 'All' },
  { id: 'open', label: 'Open' },
  { id: 'completed', label: 'Fulfilled' },
  { id: 'cancelled', label: 'Cancelled' },
]

export function OrdersPage() {
  const { data, setOrderStatus } = useStore()
  const [params, setParams] = useSearchParams()
  const filter = params.get('view') ?? 'all'
  const query = params.get('q') ?? ''
  const selectedId = params.get('order')
  const selected = data.orders.find((order) => order.id === selectedId) ?? null

  const rows = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return [...data.orders]
      .filter((order) => {
        if (filter === 'open') return order.status === 'confirmed' || order.status === 'preparing' || order.status === 'onTheWay'
        if (filter === 'completed') return order.status === 'completed'
        if (filter === 'cancelled') return order.status === 'cancelled'
        return true
      })
      .filter((order) => {
        if (!needle) return true
        return (
          order.id.toLowerCase().includes(needle) ||
          order.contactName.toLowerCase().includes(needle) ||
          order.contactPhone.includes(needle)
        )
      })
      .sort((a, b) => +new Date(b.placedAt) - +new Date(a.placedAt))
  }, [data.orders, filter, query])

  function patch(key: string, value: string) {
    const next = new URLSearchParams(params)
    if (value) next.set(key, value)
    else next.delete(key)
    setParams(next)
  }

  return (
    <>
      <PageHeader title="Orders" lede="Move an order from confirmed to delivered, or cancel it." />
      <div className="filters">
        <input
          className="search"
          placeholder="Search id, name or phone"
          value={query}
          onChange={(event) => patch('q', event.target.value)}
        />
        {filters.map((item) => (
          <button key={item.id} type="button" className={filter === item.id ? 'chip on' : 'chip'} onClick={() => patch('view', item.id === 'all' ? '' : item.id)}>
            {item.label}
          </button>
        ))}
      </div>
      <div className="table-wrap orders">
        <table>
          <thead>
            <tr>
              <th>Order</th>
              <th>Customer</th>
              <th>Placed</th>
              <th>Status</th>
              <th className="num">Total</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((order) => (
              <tr
                key={order.id}
                className={order.id === selectedId ? 'selected' : undefined}
                role="button"
                tabIndex={0}
                onClick={() => patch('order', order.id)}
                onKeyDown={(event) => {
                  if (event.key === 'Enter' || event.key === ' ') {
                    event.preventDefault()
                    patch('order', order.id)
                  }
                }}
              >
                <td>
                  <strong>{order.id}</strong>
                  <small className="block">
                    {order.lines.length} {order.lines.length === 1 ? 'pair' : 'lines'} · {fulfilmentLabel(order.fulfilment)}
                  </small>
                </td>
                <td>
                  {order.contactName}
                  <small className="block">{order.contactPhone}</small>
                </td>
                <td className="muted">{formatWhen(order.placedAt)}</td>
                <td>
                  <span className={`pill tone-${statusTone(order.status)}`}>{statusLabel(order)}</span>
                </td>
                <td className="num">{formatRupees(order.total)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {rows.length === 0 ? <p className="empty">No orders in this view.</p> : null}
      </div>
      {selected ? (
        <OrderDrawer
          order={selected}
          branchName={data.branches.find((branch) => branch.id === selected.branchId)?.name ?? selected.branchId}
          onClose={() => patch('order', '')}
          onStatus={(status) => setOrderStatus(selected.id, status)}
        />
      ) : null}
    </>
  )
}

function OrderDrawer({
  order,
  branchName,
  onClose,
  onStatus,
}: {
  order: Order
  branchName: string
  onClose: () => void
  onStatus: (status: OrderStatus) => Promise<string | null>
}) {
  const [error, setError] = useState('')
  const advance = nextStatus(order.status)

  async function change(status: OrderStatus) {
    const problem = await onStatus(status)
    setError(problem ?? '')
  }
  const advanceLabel = nextStatusLabel(order)
  const steps = ['Confirmed', 'Preparing', order.fulfilment === 'pickup' ? 'Ready' : 'On the way', order.fulfilment === 'pickup' ? 'Collected' : 'Delivered']
  const stepIndex = ['confirmed', 'preparing', 'onTheWay', 'completed'].indexOf(order.status)

  return (
    <div className="scrim" onClick={onClose}>
      <aside className="drawer" role="dialog" aria-label={order.id} onClick={(event) => event.stopPropagation()}>
        <header>
          <div>
            <p className="kicker">{order.id}</p>
            <h2>{statusLabel(order)}</h2>
          </div>
          <button type="button" className="icon-btn" onClick={onClose} aria-label="Close">
            ×
          </button>
        </header>
        {order.status === 'cancelled' ? (
          <p className="banner tight">This order was cancelled.</p>
        ) : (
          <ol className="steps">
            {steps.map((label, index) => (
              <li key={label} className={index <= stepIndex ? 'on' : undefined}>
                {label}
              </li>
            ))}
          </ol>
        )}
        <ul className="lines">
          {order.lines.map((line) => (
            <li key={`${line.productId}-${line.color}-${line.size}`}>
              <img src={line.imageUrl} alt="" />
              <div>
                <strong>{line.name}</strong>
                <small>
                  {line.color} · UK {line.size} · ×{line.quantity}
                </small>
              </div>
              <span>{formatRupees(line.unitPrice * line.quantity)}</span>
            </li>
          ))}
        </ul>
        <dl className="money">
          <div>
            <dt>Subtotal</dt>
            <dd>{formatRupees(order.subtotal)}</dd>
          </div>
          <div>
            <dt>Discount{order.couponCode ? ` · ${order.couponCode}` : ''}</dt>
            <dd>{order.discount ? `-${formatRupees(order.discount)}` : '—'}</dd>
          </div>
          <div>
            <dt>Delivery</dt>
            <dd>{order.deliveryFee ? formatRupees(order.deliveryFee) : 'Free'}</dd>
          </div>
          <div className="total">
            <dt>Total</dt>
            <dd>{formatRupees(order.total)}</dd>
          </div>
        </dl>
        <dl className="facts">
          <div>
            <dt>Customer</dt>
            <dd>
              {order.contactName}
              <br />
              {order.contactPhone}
            </dd>
          </div>
          <div>
            <dt>{order.fulfilment === 'pickup' ? 'Pickup' : 'Deliver to'}</dt>
            <dd>{order.destination}</dd>
          </div>
          <div>
            <dt>Branch</dt>
            <dd>{branchName}</dd>
          </div>
          <div>
            <dt>Payment</dt>
            <dd>{paymentLabel(order.paymentMethod)}</dd>
          </div>
        </dl>
        <FormError message={error} />
        <div className="actions">
          {advance && advanceLabel ? (
            <button type="button" className="btn primary" onClick={() => change(advance)}>
              {advanceLabel}
            </button>
          ) : null}
          {canCancel(order.status) ? (
            <button type="button" className="btn danger" onClick={() => change('cancelled')}>
              Cancel order
            </button>
          ) : null}
          {order.status === 'cancelled' ? (
            <button type="button" className="btn ghost" onClick={() => change('confirmed')}>
              Reopen as confirmed
            </button>
          ) : null}
        </div>
      </aside>
    </div>
  )
}
