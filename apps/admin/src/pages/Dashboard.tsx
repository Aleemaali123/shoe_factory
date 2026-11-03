import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { RevenueChart } from '../components/RevenueChart'
import { PageHeader } from '../components/ui'
import { getOverview, type Overview } from '../data/api'
import { formatRupees, formatWhen, statusLabel, statusTone } from '../lib/format'
import { stockLabel, stockTone } from '../lib/stock'

export function DashboardPage() {
  const [overview, setOverview] = useState<Overview | null>(null)
  const [error, setError] = useState('')

  useEffect(() => {
    let live = true
    void getOverview()
      .then((data) => {
        if (!live) return
        setOverview(data)
        setError('')
      })
      .catch((err: unknown) => {
        if (!live) return
        setError(err instanceof Error ? err.message : 'Could not load the overview.')
      })
    return () => {
      live = false
    }
  }, [])

  return (
    <>
      <PageHeader title="Overview" lede="Monthly revenue, open orders and products that need stock." />
      {error ? <p className="banner">{error}</p> : null}
      {!overview && !error ? <p className="empty">Loading the desk.</p> : null}
      {overview ? (
        <>
          <section className="stats">
            <article className="stat">
              <span>Booked sales</span>
              <strong>{formatRupees(overview.bookedSales)}</strong>
              <em>Excludes cancelled orders</em>
            </article>
            <article className="stat">
              <span>Fulfilled</span>
              <strong>{formatRupees(overview.fulfilledSales)}</strong>
              <em>{overview.fulfilledCount} delivered or collected</em>
            </article>
            <article className="stat">
              <span>Open orders</span>
              <strong>{overview.openOrders}</strong>
              <em>Confirmed, preparing or on the way</em>
            </article>
            <article className="stat">
              <span>Stock alerts</span>
              <strong>{overview.stockAlerts}</strong>
              <em>Low or out of stock</em>
            </article>
          </section>
          <RevenueChart months={overview.months} />
          <section className="card">
            <div className="card-head">
              <h2>Products to watch</h2>
              <Link to="/products">All products</Link>
            </div>
            {overview.attention.length === 0 ? <p className="empty">Every listed product has stock to spare.</p> : null}
            <ul className="stack">
              {overview.attention.map((product) => (
                <li key={product.id}>
                  <span>{product.name}</span>
                  <strong>
                    {product.stock} on hand · <span className={`pill tone-${stockTone(product.state)}`}>{stockLabel(product.state)}</span>
                  </strong>
                </li>
              ))}
            </ul>
          </section>
          <section className="card">
            <div className="card-head">
              <h2>Recent orders</h2>
              <Link to="/orders">All orders</Link>
            </div>
            {overview.recent.length === 0 ? <p className="empty">No orders yet.</p> : null}
            <div className="table-wrap plain">
              <table>
                <tbody>
                  {overview.recent.map((order) => (
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
      ) : null}
    </>
  )
}
