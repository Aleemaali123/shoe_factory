import type {
  Address,
  Cart,
  Fulfilment,
  Notice,
  Order,
  PaymentMethod,
  Product,
  Profile,
  Quote,
  Session,
} from '../types'

const base = (import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:4000').replace(/\/$/, '')
const TOKEN_KEY = 'sf-shop-token'

export class ApiError extends Error {
  statusCode?: number

  constructor(message: string, statusCode?: number) {
    super(message)
    this.name = 'ApiError'
    this.statusCode = statusCode
  }
}

let token = localStorage.getItem(TOKEN_KEY)

export function setToken(next: string | null) {
  token = next
  if (next) localStorage.setItem(TOKEN_KEY, next)
  else localStorage.removeItem(TOKEN_KEY)
}

export async function request<T>(path: string, init?: RequestInit): Promise<T> {
  let response: Response
  try {
    response = await fetch(`${base}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...(init?.headers ?? {}),
      },
    })
  } catch {
    throw new ApiError('The shop API is not reachable. Start it from the backend folder, then try again.')
  }
  const body = (await response.json().catch(() => ({}))) as { data?: T; error?: string }
  if (!response.ok) {
    throw new ApiError(body.error || 'The shop API could not complete that request.', response.status)
  }
  return body.data as T
}

let opening: Promise<Session> | null = null

async function openSessionOnce() {
  if (token) {
    try {
      return await request<Session>('/api/session')
    } catch (error) {
      if (!(error instanceof ApiError) || error.statusCode !== 401) throw error
      setToken(null)
    }
  }
  const opened = await request<Session>('/api/session', { method: 'POST' })
  if (opened.token) setToken(opened.token)
  return opened
}

export function openSession() {
  opening ??= openSessionOnce().finally(() => {
    opening = null
  })
  return opening
}

export function getProduct(id: string) {
  return request<Product>(`/api/catalog/products/${encodeURIComponent(id)}`)
}

export function addToCart(body: { productId: string; size: number; color: string; quantity: number }) {
  return request<{ added: boolean; message: string; cart: Cart }>('/api/cart/items', {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function setQuantity(id: string, quantity: number) {
  return request<Cart>(`/api/cart/items/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: JSON.stringify({ quantity }),
  })
}

export function removeItem(id: string) {
  return request<Cart>(`/api/cart/items/${encodeURIComponent(id)}`, { method: 'DELETE' })
}

export function applyCoupon(code: string, pickup: boolean) {
  return request<{ accepted: boolean; message: string; cart: Cart }>('/api/cart/coupon', {
    method: 'POST',
    body: JSON.stringify({ code, pickup }),
  })
}

export function clearCoupon() {
  return request<Cart>('/api/cart/coupon', { method: 'DELETE' })
}

export function toggleWishlist(productId: string) {
  return request<string[]>(`/api/wishlist/${encodeURIComponent(productId)}`, { method: 'POST' })
}

export function requestOtp(phone: string) {
  return request<{ code: string; registered: boolean }>('/api/auth/otp/request', {
    method: 'POST',
    body: JSON.stringify({ phone }),
  })
}

export function verifyOtp(phone: string, code: string) {
  return request<Profile & { needsProfile: boolean; signedIn: boolean }>('/api/auth/otp/verify', {
    method: 'POST',
    body: JSON.stringify({ phone, code }),
  })
}

export function registerWithOtp(body: { name: string; email: string; phone: string; code: string }) {
  return request<Profile>('/api/auth/otp/register', {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function login(email: string, password: string) {
  return request<Profile>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
}

export function logout() {
  return request<Profile>('/api/auth/logout', { method: 'POST' })
}

export function requestPasswordReset(email: string) {
  return request<{ code: string; phone: string }>('/api/auth/password/reset/request', {
    method: 'POST',
    body: JSON.stringify({ email }),
  })
}

export function resetPassword(body: {
  email: string
  code: string
  password: string
  confirmPassword: string
}) {
  return request<{ reset: boolean }>('/api/auth/password/reset', {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function updateProfile(body: { name: string; email: string; phone: string }) {
  return request<Profile>('/api/auth/me', {
    method: 'PATCH',
    body: JSON.stringify(body),
  })
}

export function saveAddress(address: Omit<Address, 'id' | 'isDefault'> & { id?: string }) {
  const path = address.id
    ? `/api/profile/addresses/${encodeURIComponent(address.id)}`
    : '/api/profile/addresses'
  return request<Address[]>(path, {
    method: address.id ? 'PATCH' : 'POST',
    body: JSON.stringify(address),
  })
}

export function deleteAddress(id: string) {
  return request<Address[]>(`/api/profile/addresses/${encodeURIComponent(id)}`, { method: 'DELETE' })
}

export function setDefaultAddress(id: string) {
  return request<Address[]>(`/api/profile/addresses/${encodeURIComponent(id)}/default`, { method: 'POST' })
}

export function quote(fulfilment: Fulfilment) {
  return request<Quote>('/api/checkout/quote', {
    method: 'POST',
    body: JSON.stringify({ fulfilment }),
  })
}

export function placeOrder(body: {
  fulfilment: Fulfilment
  paymentMethod: PaymentMethod
  contactName: string
  contactPhone: string
  destination: string
  paymentReference?: string
  branchId?: string
  razorpayOrderId?: string
  razorpaySignature?: string
}) {
  return request<Order>('/api/checkout', {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function razorpayConfig() {
  return request<{ enabled: boolean; keyId: string | null; mode: string | null }>('/api/payments/razorpay')
}

export function createRazorpayOrder(body: { amountPaise: number; receipt?: string }) {
  return request<{
    keyId: string
    orderId: string
    amount: number
    currency: string
    mode: string
  }>('/api/payments/razorpay/orders', {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function cancelOrder(id: string) {
  return request<{ cancelled: boolean; order: Order }>(`/api/orders/${encodeURIComponent(id)}/cancel`, {
    method: 'POST',
  })
}

export function reorder(id: string) {
  return request<{ units: number; cart: Cart }>(`/api/orders/${encodeURIComponent(id)}/reorder`, {
    method: 'POST',
  })
}

export function markNotice(id: string) {
  return request<Notice[]>(`/api/notices/${encodeURIComponent(id)}/read`, { method: 'POST' })
}

export function markAllNotices() {
  return request<Notice[]>('/api/notices/read', { method: 'POST' })
}

export function dismissNotice(id: string) {
  return request<Notice[]>(`/api/notices/${encodeURIComponent(id)}`, { method: 'DELETE' })
}
