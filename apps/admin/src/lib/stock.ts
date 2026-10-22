import type { Product, StockFilter } from '../types'

export type StockState = Exclude<StockFilter, 'all'>

export function stockState(product: Pick<Product, 'listed' | 'stock'>): StockState {
  if (!product.listed) return 'hidden'
  if (product.stock <= 0) return 'out'
  if (product.stock <= 5) return 'low'
  return 'in'
}

export function stockLabel(state: StockState) {
  if (state === 'out') return 'Out of stock'
  if (state === 'low') return 'Low stock'
  if (state === 'hidden') return 'Hidden'
  return 'In stock'
}

export function stockTone(state: StockState) {
  if (state === 'out') return 'danger'
  if (state === 'low') return 'amber'
  if (state === 'hidden') return 'ink'
  return 'good'
}
