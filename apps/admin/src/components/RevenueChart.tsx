import { useMemo, useState } from 'react'
import { formatRupees } from '../lib/format'
import { changeTone, formatChange, monthlyRevenue } from '../lib/revenue'
import type { Order } from '../types'

const size = 340
const center = size / 2
const gap = 2.4
const minSweep = 8

function point(radius: number, degrees: number) {
  const radians = ((degrees - 90) * Math.PI) / 180
  return [center + radius * Math.cos(radians), center + radius * Math.sin(radians)]
}

function slicePath(inner: number, outer: number, start: number, end: number) {
  const large = end - start > 180 ? 1 : 0
  const [x1, y1] = point(outer, start)
  const [x2, y2] = point(outer, end)
  const [x3, y3] = point(inner, end)
  const [x4, y4] = point(inner, start)
  return `M ${x1} ${y1} A ${outer} ${outer} 0 ${large} 1 ${x2} ${y2} L ${x3} ${y3} A ${inner} ${inner} 0 ${large} 0 ${x4} ${y4} Z`
}

export function RevenueChart({ orders }: { orders: Order[] }) {
  const months = useMemo(() => monthlyRevenue(orders), [orders])
  const [activeKey, setActiveKey] = useState<string | null>(null)
  const found = months.findIndex((month) => month.key === activeKey)
  const resolvedIndex = found >= 0 ? found : months.length - 1
  const active = months[resolvedIndex]
  const prior = resolvedIndex > 0 ? months[resolvedIndex - 1] : null
  const total = months.reduce((sum, month) => sum + month.revenue, 0)
  const orderCount = months.reduce((sum, month) => sum + month.orders, 0)
  const latest = months[months.length - 1]
  const previous = months[months.length - 2]
  const changes = months.flatMap((month) => (month.change === null ? [] : [month.change]))
  const average = changes.length ? changes.reduce((sum, value) => sum + value, 0) / changes.length : null
  const usable = 360 - months.length * gap
  const extra = Math.max(0, usable - months.length * minSweep)
  const share = total > 0 && active ? Math.round((active.revenue / total) * 100) : 0

  let cursor = 0
  const slices = months.map((month) => {
    const sweep = minSweep + (total > 0 ? extra * (month.revenue / total) : extra / months.length)
    const start = cursor
    const end = cursor + sweep
    cursor += sweep + gap
    return { ...month, start, end }
  })

  const summary = active
    ? `${active.full} is ${formatRupees(active.revenue)}, ${share}% of booked sales this year.`
    : 'No revenue in this range.'

  return (
    <section className="card revenue" aria-label="Monthly revenue">
      <div className="card-head">
        <div>
          <h2>Revenue growth</h2>
          <p className="lede">Each slice is one month of booked sales. A pale slice slipped from the month before.</p>
        </div>
        <label className="month-pick">
          Month
          <select value={active?.key ?? ''} onChange={(event) => setActiveKey(event.target.value)}>
            {months.map((month) => (
              <option key={month.key} value={month.key}>
                {month.full}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div className="revenue-body">
        <div className="ring-wrap">
          <svg className="revenue-ring" viewBox={`0 0 ${size} ${size}`} role="img" aria-label={summary}>
            <circle className="ring-track" cx={center} cy={center} r={118} />
            {slices.map((slice) => {
              const selected = slice.key === active?.key
              const down = slice.change !== null && slice.change < 0
              const outer = selected ? 152 : 142
              const inner = selected ? 92 : 98
              return (
                <path
                  key={slice.key}
                  className={['slice', down ? 'down' : '', selected ? 'on' : ''].filter(Boolean).join(' ')}
                  d={slicePath(inner, outer, slice.start, slice.end)}
                  tabIndex={0}
                  role="button"
                  aria-pressed={selected}
                  aria-label={`${slice.full}, ${formatRupees(slice.revenue)}, growth ${formatChange(slice.change)}`}
                  onClick={() => setActiveKey(slice.key)}
                  onKeyDown={(event) => {
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault()
                      setActiveKey(slice.key)
                    }
                  }}
                />
              )
            })}
          </svg>
          {active ? (
            <div className="ring-center">
              <span>{active.full}</span>
              <strong>{formatRupees(active.revenue)}</strong>
              <em className={changeTone(active.change)}>
                {prior ? `${formatChange(active.change)} from ${prior.label}` : 'Opening month'}
              </em>
              <small>
                {active.orders} {active.orders === 1 ? 'order' : 'orders'} · {share}% of the year
              </small>
            </div>
          ) : null}
        </div>

        <div className="revenue-stats">
          <article>
            <span>This month</span>
            <strong>{formatRupees(latest?.revenue ?? 0)}</strong>
            <em className={changeTone(latest?.change ?? null)}>
              {formatChange(latest?.change ?? null)} vs {previous?.label ?? 'last month'}
            </em>
          </article>
          <article>
            <span>Last month</span>
            <strong>{formatRupees(previous?.revenue ?? 0)}</strong>
            <em>{previous?.orders ?? 0} orders</em>
          </article>
          <article>
            <span>Last 12 months</span>
            <strong>{formatRupees(total)}</strong>
            <em>{orderCount} orders</em>
          </article>
          <article>
            <span>Avg. monthly change</span>
            <strong className={changeTone(average)}>{formatChange(average)}</strong>
            <em>Against the month before</em>
          </article>
        </div>
      </div>
    </section>
  )
}
