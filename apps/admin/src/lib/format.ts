import type { Order, OrderStatus } from '../types'

export function formatRupees(amount: number) {
  const negative = amount < 0
  const whole = Math.round(Math.abs(amount)).toString()
  const formatted = indianGroup(whole)
  return negative ? `-₹${formatted}` : `₹${formatted}`
}

function indianGroup(whole: string) {
  if (whole.length <= 3) return whole
  const last3 = whole.slice(-3)
  let rest = whole.slice(0, -3)
  const parts: string[] = []
  while (rest.length > 2) {
    parts.unshift(rest.slice(-2))
    rest = rest.slice(0, -2)
  }
  if (rest) parts.unshift(rest)
  return `${parts.join(',')},${last3}`
}

export function formatWhen(iso: string) {
  const date = new Date(iso)
  const day = date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  })
  const time = date.toLocaleTimeString('en-IN', {
    hour: 'numeric',
    minute: '2-digit',
  })
  return `${day} · ${time}`
}

export function paymentLabel(method: string) {
  if (method === 'razorpay') return 'Razorpay'
  if (method === 'upi') return 'UPI'
  if (method === 'card') return 'Credit / debit card'
  if (method === 'cod') return 'Cash on delivery'
  return method
}

export function fulfilmentLabel(value: string) {
  return value === 'pickup' ? 'Store pickup' : 'Home delivery'
}

export function statusLabel(order: Pick<Order, 'status' | 'fulfilment'>) {
  switch (order.status) {
    case 'confirmed':
      return 'Confirmed'
    case 'preparing':
      return 'Preparing'
    case 'onTheWay':
      return order.fulfilment === 'pickup' ? 'Ready for pickup' : 'Out for delivery'
    case 'completed':
      return order.fulfilment === 'pickup' ? 'Collected' : 'Delivered'
    case 'cancelled':
      return 'Cancelled'
  }
}

export function statusTone(status: OrderStatus) {
  if (status === 'cancelled') return 'danger'
  if (status === 'completed') return 'good'
  if (status === 'preparing') return 'amber'
  if (status === 'onTheWay') return 'green'
  return 'ink'
}

export function nextStatus(status: OrderStatus): OrderStatus | null {
  if (status === 'confirmed') return 'preparing'
  if (status === 'preparing') return 'onTheWay'
  if (status === 'onTheWay') return 'completed'
  return null
}

export function nextStatusLabel(order: Pick<Order, 'status' | 'fulfilment'>) {
  const next = nextStatus(order.status)
  if (next === 'preparing') return 'Mark preparing'
  if (next === 'onTheWay') {
    return order.fulfilment === 'pickup' ? 'Mark ready for pickup' : 'Mark out for delivery'
  }
  if (next === 'completed') {
    return order.fulfilment === 'pickup' ? 'Mark collected' : 'Mark delivered'
  }
  return null
}

export function canCancel(status: OrderStatus) {
  return status === 'confirmed' || status === 'preparing'
}

export function isOpen(status: OrderStatus) {
  return status === 'confirmed' || status === 'preparing' || status === 'onTheWay'
}
