import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from 'react'
import * as api from './api'
import { cartSubtotal } from '../lib/catalog'
import type { Address, Cart, Fulfilment, Order, PaymentMethod, Product, Profile, Quote, Session } from '../types'

const BRANCH_KEY = 'sf-shop-branch'

type ShopState = Omit<Session, 'token'> & { offline: string }

const empty: ShopState = {
  offline: '',
  user: null,
  addresses: [],
  cart: { items: [], couponCode: null },
  wishlist: [],
  orders: [],
  notices: [],
  branches: [],
  coupons: [],
  products: [],
  categories: ['All'],
}

function fromSession(session: Session): ShopState {
  return {
    offline: '',
    user: session.user,
    addresses: session.addresses ?? [],
    cart: session.cart ?? { items: [], couponCode: null },
    wishlist: session.wishlist ?? [],
    orders: session.orders ?? [],
    notices: session.notices ?? [],
    branches: session.branches ?? [],
    coupons: session.coupons ?? [],
    products: session.products ?? [],
    categories: session.categories?.length ? session.categories : ['All'],
  }
}

type ShopValue = ShopState & {
  ready: boolean
  flash: string
  branchId: string
  cartCount: number
  subtotal: number
  unread: number
  clearFlash: () => void
  note: (message: string) => void
  refresh: () => Promise<void>
  setBranch: (id: string) => void
  addToCart: (input: { productId: string; size: number; color: string; quantity: number }) => Promise<{
    added: boolean
    message: string
  }>
  setQuantity: (id: string, quantity: number) => Promise<Cart>
  removeItem: (id: string) => Promise<void>
  applyCoupon: (code: string, pickup: boolean) => Promise<{ accepted: boolean; message: string }>
  clearCoupon: () => Promise<void>
  toggleWish: (productId: string) => Promise<void>
  requestOtp: typeof api.requestOtp
  verifyOtp: (phone: string, code: string) => Promise<{ needsProfile: boolean }>
  registerWithOtp: (body: { name: string; email: string; phone: string; code: string }) => Promise<void>
  login: (email: string, password: string) => Promise<void>
  requestPasswordReset: typeof api.requestPasswordReset
  resetPassword: typeof api.resetPassword
  logout: () => Promise<void>
  updateProfile: (body: { name: string; email: string; phone: string }) => Promise<void>
  saveAddress: (address: Omit<Address, 'id' | 'isDefault'> & { id?: string }) => Promise<void>
  deleteAddress: (id: string) => Promise<void>
  makeDefault: (id: string) => Promise<void>
  quote: (fulfilment: Fulfilment) => Promise<Quote>
  placeOrder: (body: {
    fulfilment: Fulfilment
    paymentMethod: PaymentMethod
    contactName: string
    contactPhone: string
    destination: string
    paymentReference?: string
    branchId?: string
    razorpayOrderId?: string
    razorpaySignature?: string
  }) => Promise<Order>
  cancelOrder: (id: string) => Promise<string>
  reorder: (id: string) => Promise<string>
  markNotice: (id: string) => Promise<void>
  markAllNotices: () => Promise<void>
  dismissNotice: (id: string) => Promise<void>
  productById: (id: string) => Promise<Product>
}

const ShopContext = createContext<ShopValue | null>(null)

function useCartWriter(setState: Dispatch<SetStateAction<ShopState>>) {
  return useCallback((cart: Cart) => {
    setState((current) => ({ ...current, cart }))
  }, [setState])
}

export function ShopProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ShopState>(empty)
  const [ready, setReady] = useState(false)
  const [flash, setFlash] = useState('')
  const [branchId, setBranchId] = useState(() => localStorage.getItem(BRANCH_KEY) ?? '')
  const writeCart = useCartWriter(setState)

  const note = useCallback((message: string) => setFlash(message), [])
  const clearFlash = useCallback(() => setFlash(''), [])

  useEffect(() => {
    if (!flash) return
    const id = window.setTimeout(() => setFlash(''), 4200)
    return () => window.clearTimeout(id)
  }, [flash])

  const refresh = useCallback(async () => {
    const session = await api.openSession()
    setState(fromSession(session))
  }, [])

  useEffect(() => {
    let cancelled = false
    api
      .openSession()
      .then(async (session) => {
        if (cancelled) return
        setState(fromSession(session))
        const { loadRazorpayConfig } = await import('../lib/razorpay')
        if (!cancelled) await loadRazorpayConfig()
      })
      .catch((error: unknown) => {
        if (!cancelled) {
          const message = error instanceof Error ? error.message : 'The shop could not open.'
          setState((current) => ({ ...current, offline: message }))
        }
      })
      .finally(() => {
        if (!cancelled) setReady(true)
      })
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!state.branches.length) return
    if (state.branches.some((branch) => branch.id === branchId)) return
    const next = state.branches[0].id
    setBranchId(next)
    localStorage.setItem(BRANCH_KEY, next)
  }, [state.branches, branchId])

  const setBranch = useCallback((id: string) => {
    setBranchId(id)
    localStorage.setItem(BRANCH_KEY, id)
  }, [])

  const applyProfile = useCallback((profile: Profile) => {
    setState((current) => ({
      ...current,
      user: profile.user,
      addresses: profile.addresses ?? [],
    }))
  }, [])

  const value = useMemo<ShopValue>(() => {
    const cartCount = state.cart.items.reduce((sum, item) => sum + item.quantity, 0)
    return {
      ...state,
      ready,
      flash,
      branchId,
      cartCount,
      subtotal: cartSubtotal(state.cart.items),
      unread: state.notices.filter((notice) => !notice.read).length,
      clearFlash,
      note,
      refresh,
      setBranch,
      async addToCart(input) {
        const result = await api.addToCart(input)
        writeCart(result.cart)
        return { added: result.added, message: result.message }
      },
      async setQuantity(id, quantity) {
        const cart = await api.setQuantity(id, quantity)
        writeCart(cart)
        return cart
      },
      async removeItem(id) {
        writeCart(await api.removeItem(id))
      },
      async applyCoupon(code, pickup) {
        const result = await api.applyCoupon(code, pickup)
        writeCart(result.cart)
        return { accepted: result.accepted, message: result.message }
      },
      async clearCoupon() {
        writeCart(await api.clearCoupon())
      },
      async toggleWish(productId) {
        const wishlist = await api.toggleWishlist(productId)
        setState((current) => ({ ...current, wishlist }))
      },
      requestOtp: api.requestOtp,
      async verifyOtp(phone, code) {
        const result = await api.verifyOtp(phone, code)
        if (result.signedIn) applyProfile(result)
        return { needsProfile: result.needsProfile }
      },
      async registerWithOtp(body) {
        applyProfile(await api.registerWithOtp(body))
        await refresh()
      },
      async login(email, password) {
        applyProfile(await api.login(email, password))
        await refresh()
      },
      requestPasswordReset: api.requestPasswordReset,
      resetPassword: api.resetPassword,
      async logout() {
        applyProfile(await api.logout())
        await refresh()
      },
      async updateProfile(body) {
        applyProfile(await api.updateProfile(body))
      },
      async saveAddress(address) {
        const addresses = await api.saveAddress(address)
        setState((current) => ({ ...current, addresses }))
      },
      async deleteAddress(id) {
        const addresses = await api.deleteAddress(id)
        setState((current) => ({ ...current, addresses }))
      },
      async makeDefault(id) {
        const addresses = await api.setDefaultAddress(id)
        setState((current) => ({ ...current, addresses }))
      },
      quote: api.quote,
      async placeOrder(body) {
        const order = await api.placeOrder(body)
        await refresh()
        return order
      },
      async cancelOrder(id) {
        const result = await api.cancelOrder(id)
        await refresh()
        return result.cancelled ? 'Order cancelled.' : 'This order can no longer be cancelled.'
      },
      async reorder(id) {
        const result = await api.reorder(id)
        writeCart(result.cart)
        await refresh()
        return result.units > 0
          ? `${result.units} item${result.units === 1 ? '' : 's'} added to your cart.`
          : 'Nothing from that order could be added.'
      },
      async markNotice(id) {
        const notices = await api.markNotice(id)
        setState((current) => ({ ...current, notices }))
      },
      async markAllNotices() {
        const notices = await api.markAllNotices()
        setState((current) => ({ ...current, notices }))
      },
      async dismissNotice(id) {
        const notices = await api.dismissNotice(id)
        setState((current) => ({ ...current, notices }))
      },
      async productById(id) {
        const known = state.products.find((product) => product.id === id)
        if (known) return known
        return api.getProduct(id)
      },
    }
  }, [applyProfile, branchId, clearFlash, note, ready, refresh, setBranch, state, writeCart])

  return <ShopContext.Provider value={value}>{children}</ShopContext.Provider>
}

export function useShop() {
  const value = useContext(ShopContext)
  if (!value) throw new Error('useShop must be used inside ShopProvider')
  return value
}
