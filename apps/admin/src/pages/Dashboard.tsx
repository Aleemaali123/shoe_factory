import { Link } from 'react-router-dom'
import { RevenueChart } from '../components/RevenueChart'
import { PageHeader } from '../components/ui'
import { useCatalog } from '../data/catalog'
import { useStore } from '../data/store'
import { formatRupees, formatWhen, isOpen, statusLabel, statusTone } from '../lib/format'
import { stockLabel, stockState, stockTone } from '../lib/stock'

export function DashboardPage() {
  const { data } = useStore()
  const { products } = useCatalog()
  const open = data.orders.filter((order) => isOpen(order.status))
  const booked = data.orders.filter((order) => order.status !== 'cancelled')
  const fulfilled = data.orders.filter((order) => order.status === 'completed')
  const bookedSales = booked.reduce((sum, order) => sum + order.total, 0)
  const fulfilledSales = fulfilled.reduce((sum, order) => sum + order.total, 0)
  const attention = products.filter((product) => {
    const state = stockState(product)
    return state === 'low' || state === 'out'
  })
  const recent = [...data.orders].sort((a, b) => +new Date(b.placedAt) - +new Date(a.placedAt)).slice(0, 5)

  return (
    <>
      <PageHeader title="Overview" lede="Monthly revenue, open orders and products that need stock." />
      <p className="banner">
        Products added here are stored on the shop API and appear in the app. Orders on this desk stay in this browser.
      </p>
      <section className="stats">
        <article className="stat">
          <span>Booked sales</span>
          <strong>{formatRupees(bookedSales)}</strong>
          <em>Excludes cancelled orders</em>
        </article>
        <article className="stat">
          <span>Fulfilled</span>
          <strong>{formatRupees(fulfilledSales)}</strong>
          <em>{fulfilled.length} delivered or collected</em>
        </article>
        <article className="stat">
          <span>Open orders</span>
          <strong>{open.length}</strong>
          <em>Confirmed, preparing or on the way</em>
        </article>
        <article className="stat">
          <span>Stock alerts</span>
          <strong>{attention.length}</strong>
          <em>Low or out of stock</em>
        </article>
      </section>
      <RevenueChart orders={data.orders} />
      <section className="card">
        <div className="card-head">
          <h2>Products to watch</h2>
          <Link to="/products">All products</Link>
        </div>
        {attention.length === 0 ? <p className="empty">Every listed product has stock to spare.</p> : null}
        <ul className="stack">
          {attention.map((product) => {
            const state = stockState(product)
            return (
              <li key={product.id}>
                <span>{product.name}</span>
                <strong>
                  {product.stock} on hand · <span className={`pill tone-${stockTone(state)}`}>{stockLabel(state)}</span>
                </strong>
              </li>
            )
          })}
        </ul>
      </section>
      <section className="card">
        <div className="card-head">
          <h2>Recent orders</h2>
          <Link to="/orders">All orders</Link>
        </div>
        <div className="table-wrap plain">
          <table>
            <tbody>
              {recent.map((order) => (
                <tr key={order.id}>
                  <td>
                    <Link className="pair" to={`/orders?order=${order.id}`}>
                      <strong>{order.id}</strong>
                      <small>{order.contactName}</small>
                    </Link>
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
        </div>
      </section>
    </>
  )
}
