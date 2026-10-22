import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  createBranch,
  createCoupon,
  createNotice,
  deleteBranch as removeBranch,
  deleteCoupon as removeCoupon,
  deleteNotice as removeNotice,
  listBranches,
  listCoupons,
  listCustomers,
  listNotices,
  listOrders,
  restoreDesk,
  saveCustomer as putCustomer,
  setOrderStatus as putOrderStatus,
  updateBranch,
  updateCoupon,
  updateNotice,
} from './api'
import type { AdminData, Branch, Coupon, Customer, Notice, OrderStatus } from '../types'

const empty: AdminData = {
  products: [],
  orders: [],
  customers: [],
  branches: [],
  coupons: [],
  notices: [],
}

type Store = {
  data: AdminData
  loading: boolean
  error: string
  flash: string | null
  dismissFlash: () => void
  refresh: () => Promise<void>
  setOrderStatus: (id: string, status: OrderStatus) => Promise<string | null>
  saveCustomer: (customer: Customer) => Promise<string | null>
  saveBranch: (branch: Branch, creating?: boolean) => Promise<string | null>
  deleteBranch: (id: string) => Promise<void>
  saveCoupon: (coupon: Coupon, previousCode?: string) => Promise<string | null>
  deleteCoupon: (code: string) => Promise<void>
  saveNotice: (notice: Notice) => Promise<string | null>
  deleteNotice: (id: string) => Promise<void>
  resetDemo: () => Promise<void>
}

const StoreContext = createContext<Store | null>(null)

function messageOf(err: unknown, fallback: string) {
  return err instanceof Error ? err.message : fallback
}

export function StoreProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<AdminData>(empty)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [flash, setFlash] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    try {
      const [orders, customers, branches, coupons, notices] = await Promise.all([
        listOrders(),
        listCustomers(),
        listBranches(),
        listCoupons(),
        listNotices(),
      ])
      setData((current) => ({ ...current, orders, customers, branches, coupons, notices }))
      setError('')
    } catch (err) {
      setError(messageOf(err, 'Could not load the shop desk.'))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  useEffect(() => {
    if (!flash) return
    const timer = window.setTimeout(() => setFlash(null), 2600)
    return () => window.clearTimeout(timer)
  }, [flash])

  const store = useMemo<Store>(() => {
    return {
      data,
      loading,
      error,
      flash,
      dismissFlash: () => setFlash(null),
      refresh,
      setOrderStatus: async (id, status) => {
        try {
          const saved = await putOrderStatus(id, status)
          setData((current) => ({
            ...current,
            orders: current.orders.map((order) => (order.id === id ? saved : order)),
          }))
          setError('')
          setFlash(`${id} updated.`)
          return null
        } catch (err) {
          return messageOf(err, 'Could not update that order.')
        }
      },
      saveCustomer: async (customer) => {
        try {
          const saved = await putCustomer(customer)
          setData((current) => {
            const customers = current.customers.filter((item) => item.id !== customer.id && item.id !== saved.id)
            customers.push(saved)
            return { ...current, customers }
          })
          setError('')
          setFlash(`${saved.name} saved.`)
          return null
        } catch (err) {
          return messageOf(err, 'Could not save that customer.')
        }
      },
      saveBranch: async (branch, creating = false) => {
        try {
          const saved = creating ? await createBranch(branch) : await updateBranch(branch)
          setData((current) => {
            const index = current.branches.findIndex((item) => item.id === saved.id)
            const branches = [...current.branches]
            if (index >= 0) branches[index] = saved
            else branches.push(saved)
            return { ...current, branches }
          })
          setError('')
          setFlash(`${saved.name} saved.`)
          return null
        } catch (err) {
          return messageOf(err, 'Could not save that branch.')
        }
      },
      deleteBranch: async (id) => {
        try {
          await removeBranch(id)
          setData((current) => ({
            ...current,
            branches: current.branches.filter((item) => item.id !== id),
          }))
          setError('')
          setFlash('Branch removed.')
        } catch (err) {
          setError(messageOf(err, 'Could not remove that branch.'))
        }
      },
      saveCoupon: async (coupon, previousCode) => {
        try {
          const key = (previousCode ?? coupon.code).trim().toUpperCase()
          const saved = previousCode ? await updateCoupon(coupon, key) : await createCoupon(coupon)
          setData((current) => {
            const coupons = current.coupons.filter((item) => item.code !== key && item.code !== saved.code)
            coupons.unshift(saved)
            return { ...current, coupons }
          })
          setError('')
          setFlash(`${saved.code} saved.`)
          return null
        } catch (err) {
          return messageOf(err, 'Could not save that coupon.')
        }
      },
      deleteCoupon: async (code) => {
        try {
          await removeCoupon(code)
          setData((current) => ({
            ...current,
            coupons: current.coupons.filter((item) => item.code !== code),
          }))
          setError('')
          setFlash(`${code} removed.`)
        } catch (err) {
          setError(messageOf(err, 'Could not remove that coupon.'))
        }
      },
      saveNotice: async (notice) => {
        try {
          const exists = data.notices.some((item) => item.id === notice.id)
          const saved = exists ? await updateNotice(notice) : await createNotice(notice)
          setData((current) => {
            const index = current.notices.findIndex((item) => item.id === saved.id)
            const notices = [...current.notices]
            if (index >= 0) notices[index] = saved
            else notices.unshift(saved)
            return { ...current, notices }
          })
          setError('')
          setFlash('Notice saved.')
          return null
        } catch (err) {
          return messageOf(err, 'Could not save that notice.')
        }
      },
      deleteNotice: async (id) => {
        try {
          await removeNotice(id)
          setData((current) => ({
            ...current,
            notices: current.notices.filter((item) => item.id !== id),
          }))
          setError('')
          setFlash('Notice removed.')
        } catch (err) {
          setError(messageOf(err, 'Could not remove that notice.'))
        }
      },
      resetDemo: async () => {
        try {
          const restored = await restoreDesk()
          setData((current) => ({ ...current, ...restored }))
          setError('')
          setFlash('Branches, coupons and notices restored.')
        } catch (err) {
          setError(messageOf(err, 'Could not restore the desk.'))
        }
      },
    }
  }, [data, loading, error, flash, refresh])

  return <StoreContext.Provider value={store}>{children}</StoreContext.Provider>
}

export function useStore() {
  const store = useContext(StoreContext)
  if (!store) throw new Error('useStore must be used inside StoreProvider')
  return store
}
