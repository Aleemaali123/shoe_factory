import { useState } from 'react'
import { Link, useLocation, useNavigate, useParams } from 'react-router-dom'
import { Empty, Money, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import { sizeOption } from '../lib/catalog'
import {
  canCancel,
  deliveryFeeLabel,
  formatRupees,
  formatWhen,
  fulfilmentLabel,
  orderEta,
  paymentLabel,
  statusLabel,
} from '../lib/format'

const steps = ['Confirmed', 'Preparing', 'On the way', 'Done']

export function OrderPage() {
  const { id = '' } = useParams()
  const shop = useShop()
  const navigate = useNavigate()
  const location = useLocation()
  const placedState = location.state as {
    placed?: boolean
    message?: string
    trackingUrl?: string | null
    paid?: boolean
  } | null
  const placed = Boolean(placedState?.placed)
  const placedMessage = placedState?.message
  const paidJustNow = Boolean(placedState?.paid)
  const order = shop.orders.find((item) => item.id === id)
  const trackingUrl = placedState?.trackingUrl || order?.trackingUrl || (typeof window !== 'undefined' && id
    ? `${window.location.origin}/orders/${encodeURIComponent(id)}`
    : null)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  useTitle(order ? order.id : 'Order')

  if (!order) {
    return <Empty title="Order not found" body="It may belong to another session." action="See my orders" to="/orders" />
  }

  const pickup = order.fulfilment === 'pickup'
  const labels = pickup ? ['Confirmed', 'Preparing', 'Ready', 'Collected'] : steps
  const index = order.status === 'confirmed' ? 0 : order.status === 'preparing' ? 1 : order.status === 'onTheWay' ? 2 : order.status === 'completed' ? 3 : -1

  return (
    <div className="layout">
      <section className="panel">
        {placed ? (
          <div className="banner ok">
            <p className="ok" style={{ margin: 0 }}>
              {paidJustNow ? 'Payment received. ' : ''}Order placed. {placedMessage || orderEta(order)}
            </p>
            {trackingUrl ? (
              <p style={{ margin: '8px 0 0' }}>
                Tracking link:{' '}
                <a href={trackingUrl}>{trackingUrl}</a>
              </p>
            ) : null}
          </div>
        ) : null}
        <p className="muted">{formatWhen(order.placedAt)}</p>
        <h2>{order.id}</h2>
        <p>{statusLabel(order)} · {orderEta(order)}</p>
        {index >= 0 ? (
          <div className="steps" aria-hidden="true">
            {labels.map((label, step) => (
              <span key={label} className={step <= index ? 'on' : ''} title={label} />
            ))}
          </div>
        ) : (
          <p className="error">Cancelled</p>
        )}
        <p className="muted">{labels.join(' · ')}</p>
        {order.lines.map((line) => (
          <div className="order-line" key={`${line.productId}-${line.size}-${line.color}`}>
            <img src={line.imageUrl} alt="" />
            <div>
              <strong>
                <Link to={`/product/${line.productId}`}>{line.name}</Link>
              </strong>
              <p className="muted">
                {line.color} · {sizeOption(shop.products.find((product) => product.id === line.productId)?.category ?? '', line.size)} · × {line.quantity}
              </p>
            </div>
            <strong className="end">{formatRupees(line.unitPrice * line.quantity)}</strong>
          </div>
        ))}
        {error ? <p className="error">{error}</p> : null}
        <div className="actions" style={{ marginTop: 16 }}>
          {canCancel(order.status) ? (
            <button
              className="btn danger"
              type="button"
              disabled={busy}
              onClick={() => {
                setBusy(true)
                void shop.cancelOrder(order.id).then(
                  (message) => shop.note(message),
                  (caught: unknown) => setError(caught instanceof Error ? caught.message : 'Could not cancel the order.'),
                ).finally(() => setBusy(false))
              }}
            >
              Cancel order
            </button>
          ) : null}
          <button
            className="btn line"
            type="button"
            disabled={busy}
            onClick={() => {
              setBusy(true)
              void shop.reorder(order.id).then(
                (message) => {
                  shop.note(message)
                  navigate('/cart')
                },
                (caught: unknown) => setError(caught instanceof Error ? caught.message : 'Could not order this again.'),
              ).finally(() => setBusy(false))
            }}
          >
            Order again
          </button>
        </div>
      </section>
      <aside className="panel">
        <h2>Details</h2>
        <p><strong>{order.contactName}</strong></p>
        <p>{order.contactPhone}</p>
        <p>{fulfilmentLabel(order.fulfilment)}</p>
        <p>{order.destination}</p>
        <p className="muted">{paymentLabel(order.paymentMethod)}</p>
        <Money label="Subtotal" value={formatRupees(order.subtotal)} />
        <Money label="Discount" value={order.discount ? `-${formatRupees(order.discount)}` : formatRupees(0)} />
        <Money label="Delivery" value={deliveryFeeLabel(order.deliveryFee, pickup, order.subtotal)} />
        <Money label="Total" value={formatRupees(order.total)} total />
      </aside>
    </div>
  )
}
