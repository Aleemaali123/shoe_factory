import {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { createSeed } from './seed'
import { stockLabel, stockState } from '../lib/stock'
import { productPhotos, type AdminData, type Branch, type Coupon, type Customer, type Notice, type OrderStatus, type Product } from '../types'

const KEY = 'sf-admin-v2'

type Store = {
  data: AdminData
  flash: string | null
  dismissFlash: () => void
  saveProduct: (product: Product) => void
  deleteProduct: (id: string) => void
  adjustStock: (id: string, delta: number) => void
  setOrderStatus: (id: string, status: OrderStatus) => void
  saveCustomer: (customer: Customer) => void
  saveBranch: (branch: Branch, creating?: boolean) => boolean
  deleteBranch: (id: string) => void
  saveCoupon: (coupon: Coupon, previousCode?: string) => boolean
  deleteCoupon: (code: string) => void
  saveNotice: (notice: Notice) => void
  deleteNotice: (id: string) => void
  resetDemo: () => void
}

const StoreContext = createContext<Store | null>(null)

function load(): AdminData {
  try {
    const raw = localStorage.getItem(KEY)
    if (!raw) return createSeed()
    const parsed = JSON.parse(raw) as AdminData
    if (!Array.isArray(parsed.products) || !Array.isArray(parsed.orders)) return createSeed()
    const next: AdminData = {
      ...parsed,
      products: parsed.products.map((product) => {
        const images = productPhotos(product)
        return { ...product, images, imageUrl: images[0]?.url ?? '' }
      }),
    }
    if (!next.revenueBackfill) {
      const history = createSeed().orders.filter((order) => order.id.startsWith('SF-H'))
      const ids = new Set(next.orders.map((order) => order.id))
      const missing = history.filter((order) => !ids.has(order.id))
      next.orders = [...missing, ...next.orders]
      for (const order of missing) {
        const customer = next.customers?.find((item) => item.id === order.customerId)
        if (customer && customer.joinedAt > order.placedAt) customer.joinedAt = order.placedAt
      }
      next.revenueBackfill = true
    }
    return next
  } catch {
    return createSeed()
  }
}

export function StoreProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<AdminData>(load)
  const [flash, setFlash] = useState<string | null>(null)

  useEffect(() => {
    localStorage.setItem(KEY, JSON.stringify(data))
  }, [data])

  useEffect(() => {
    if (!flash) return
    const timer = window.setTimeout(() => setFlash(null), 2600)
    return () => window.clearTimeout(timer)
  }, [flash])

  const store = useMemo<Store>(() => {
    function change(recipe: (current: AdminData) => AdminData, message: string) {
      setData(recipe)
      setFlash(message)
    }

    return {
      data,
      flash,
      dismissFlash: () => setFlash(null),
      saveProduct: (product) => {
        change((current) => {
          const index = current.products.findIndex((item) => item.id === product.id)
          const products = [...current.products]
          if (index >= 0) products[index] = product
          else products.unshift(product)
          return { ...current, products }
        }, `${product.name} saved · ${stockLabel(stockState(product))}.`)
      },
      deleteProduct: (id) => {
        const name = data.products.find((item) => item.id === id)?.name ?? 'Product'
        change(
          (current) => ({
            ...current,
            products: current.products.filter((item) => item.id !== id),
          }),
          `${name} removed.`,
        )
      },
      adjustStock: (id, delta) => {
        const current = data.products.find((item) => item.id === id)
        if (!current) return
        const stock = Math.max(0, current.stock + delta)
        const next = { ...current, stock }
        change(
          (state) => ({
            ...state,
            products: state.products.map((item) => (item.id === id ? next : item)),
          }),
          `${next.name} · ${stock} on hand · ${stockLabel(stockState(next))}.`,
        )
      },
      setOrderStatus: (id, status) => {
        change(
          (current) => ({
            ...current,
            orders: current.orders.map((order) => (order.id === id ? { ...order, status } : order)),
          }),
          `${id} updated.`,
        )
      },
      saveCustomer: (customer) => {
        change(
          (current) => ({
            ...current,
            customers: current.customers.map((item) => (item.id === customer.id ? customer : item)),
          }),
          `${customer.name} saved.`,
        )
      },
      saveBranch: (branch, creating = false) => {
        const id = branch.id.trim().toLowerCase()
        const next = { ...branch, id }
        if (!id) {
          setFlash('Give the branch an id.')
          return false
        }
        if (creating && data.branches.some((item) => item.id === id)) {
          setFlash('That branch id already exists.')
          return false
        }
        change((current) => {
          const index = current.branches.findIndex((item) => item.id === id)
          const list = [...current.branches]
          if (index >= 0) list[index] = next
          else list.push(next)
          return { ...current, branches: list }
        }, `${next.name} saved.`)
        return true
      },
      deleteBranch: (id) => {
        if (data.branches.length <= 1) {
          setFlash('Keep at least one branch.')
          return
        }
        change(
          (current) => ({
            ...current,
            branches: current.branches.filter((item) => item.id !== id),
          }),
          'Branch removed.',
        )
      },
      saveCoupon: (coupon, previousCode) => {
        const code = coupon.code.trim().toUpperCase()
        const key = (previousCode ?? code).trim().toUpperCase()
        if (!code) {
          setFlash('Enter a coupon code.')
          return false
        }
        if (data.coupons.some((item) => item.code === code && item.code !== key)) {
          setFlash('That coupon code already exists.')
          return false
        }
        const next = { ...coupon, code }
        change((current) => {
          const list = current.coupons.filter((item) => item.code !== key)
          list.unshift(next)
          return { ...current, coupons: list }
        }, `${code} saved.`)
        return true
      },
      deleteCoupon: (code) => {
        change(
          (current) => ({
            ...current,
            coupons: current.coupons.filter((item) => item.code !== code),
          }),
          `${code} removed.`,
        )
      },
      saveNotice: (notice) => {
        change((current) => {
          const index = current.notices.findIndex((item) => item.id === notice.id)
          const notices = [...current.notices]
          if (index >= 0) notices[index] = notice
          else notices.unshift(notice)
          return { ...current, notices }
        }, 'Notice saved.')
      },
      deleteNotice: (id) => {
        change(
          (current) => ({
            ...current,
            notices: current.notices.filter((item) => item.id !== id),
          }),
          'Notice removed.',
        )
      },
      resetDemo: () => change(() => createSeed(), 'Demo data restored.'),
    }
  }, [data, flash])

  return <StoreContext.Provider value={store}>{children}</StoreContext.Provider>
}

export function useStore() {
  const store = useContext(StoreContext)
  if (!store) throw new Error('useStore must be used inside StoreProvider')
  return store
}
