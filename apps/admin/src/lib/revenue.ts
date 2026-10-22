import type { Order } from '../types'
import { formatRupees } from './format'

export type MonthRevenue = {
  key: string
  label: string
  full: string
  revenue: number
  orders: number
  change: number | null
}

export function monthlyRevenue(orders: Order[], span = 12, now = new Date()): MonthRevenue[] {
  const cursor = new Date(now.getFullYear(), now.getMonth(), 1)
  const months: MonthRevenue[] = []
  for (let i = span - 1; i >= 0; i--) {
    const date = new Date(cursor.getFullYear(), cursor.getMonth() - i, 1)
    const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
    months.push({
      key,
      label: date.toLocaleDateString('en-IN', { month: 'short' }),
      full: date.toLocaleDateString('en-IN', { month: 'long', year: 'numeric' }),
      revenue: 0,
      orders: 0,
      change: null,
    })
  }

  const index = new Map(months.map((month, position) => [month.key, position]))
  for (const order of orders) {
    if (order.status === 'cancelled') continue
    const placed = new Date(order.placedAt)
    if (Number.isNaN(placed.getTime())) continue
    const key = `${placed.getFullYear()}-${String(placed.getMonth() + 1).padStart(2, '0')}`
    const slot = index.get(key)
    if (slot === undefined) continue
    months[slot].revenue += order.total
    months[slot].orders += 1
  }

  for (let i = 1; i < months.length; i++) {
    const previous = months[i - 1].revenue
    if (previous === 0) continue
    months[i].change = ((months[i].revenue - previous) / previous) * 100
  }
  return months
}

export function formatChange(change: number | null) {
  if (change === null) return '—'
  const rounded = Math.round(change)
  if (rounded === 0) return '0%'
  return rounded > 0 ? `+${rounded}%` : `${rounded}%`
}

export function changeTone(change: number | null) {
  if (change === null || Math.round(change) === 0) return 'flat'
  return change > 0 ? 'up' : 'down'
}

export function formatCompactRupees(amount: number) {
  const abs = Math.abs(amount)
  const sign = amount < 0 ? '−' : ''
  if (abs >= 10000000) return `${sign}₹${trim(abs / 10000000)}Cr`
  if (abs >= 100000) return `${sign}₹${trim(abs / 100000)}L`
  if (abs >= 1000) return `${sign}₹${trim(abs / 1000)}k`
  return formatRupees(amount)
}

function trim(value: number) {
  const rounded = value >= 10 ? Math.round(value) : Math.round(value * 10) / 10
  return Number.isInteger(rounded) ? String(rounded) : rounded.toFixed(1)
}

export function niceCeiling(value: number) {
  if (value <= 0) return 1000
  const padded = value * 1.12
  const magnitude = 10 ** Math.floor(Math.log10(padded))
  const normalized = padded / magnitude
  const steps = [1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]
  const nice = steps.find((step) => step >= normalized - 1e-9) ?? 10
  return nice * magnitude
}
