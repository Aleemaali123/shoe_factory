import { Link } from 'react-router-dom'
import { Empty, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import { formatRupees, formatWhen, fulfilmentLabel, statusLabel, statusTone } from '../lib/format'

export function OrdersPage() {
  useTitle('Orders')
  const shop = useShop()

  if (!shop.orders.length) {
    return <Empty title="No orders yet" body="When you check out, the order will show up here." action="Browse the shop" to="/shop" />
  }

  return (
    <section>
      <div className="section-head">
        <h2>My orders</h2>
      </div>
      <div className="orders">
        {shop.orders.map((order) => (
          <Link key={order.id} className="order" to={`/orders/${order.id}`}>
            <div>
              <strong>{order.id}</strong>
              <p className="muted">{formatWhen(order.placedAt)} · {fulfilmentLabel(order.fulfilment)}</p>
              <p>{order.lines[0]?.name}{order.lines.length > 1 ? ` + ${order.lines.length - 1} more` : ''}</p>
            </div>
            <div>
              <span className={`pill ${statusTone(order.status)}`}>{statusLabel(order)}</span>
              <p style={{ marginTop: 8, textAlign: 'right' }}><strong>{formatRupees(order.total)}</strong></p>
            </div>
          </Link>
        ))}
      </div>
    </section>
  )
}
