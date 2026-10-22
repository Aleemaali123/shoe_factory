import type { Branch, Coupon, Customer, Notice, Order, OrderStatus } from '../types'

const base = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, '') || 'http://127.0.0.1:4000'

export class ApiError extends Error {}

export async function request<T>(path: string, init?: RequestInit): Promise<T> {
  let response: Response
  try {
    response = await fetch(`${base}${path}`, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        ...(init?.headers ?? {}),
      },
    })
  } catch {
    throw new ApiError('The shop API is not reachable. Start it, then try again.')
  }
  const body = (await response.json().catch(() => ({}))) as { data?: T; error?: string }
  if (!response.ok) throw new ApiError(body.error || 'The shop API could not complete that request.')
  return body.data as T
}

export type AdminProfile = {
  name: string
  email: string
  phone: string
}

export function listOrders() {
  return request<Order[]>('/api/admin/orders')
}

export function setOrderStatus(id: string, status: OrderStatus) {
  return request<Order>(`/api/admin/orders/${encodeURIComponent(id)}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  })
}

export function listCustomers() {
  return request<Customer[]>('/api/admin/customers')
}

export function saveCustomer(customer: Customer) {
  return request<Customer>(`/api/admin/customers/${encodeURIComponent(customer.id)}`, {
    method: 'PATCH',
    body: JSON.stringify(customer),
  })
}

export function listBranches() {
  return request<Branch[]>('/api/admin/branches')
}

export function createBranch(branch: Branch) {
  return request<Branch>('/api/admin/branches', {
    method: 'POST',
    body: JSON.stringify(branch),
  })
}

export function updateBranch(branch: Branch) {
  return request<Branch>(`/api/admin/branches/${encodeURIComponent(branch.id)}`, {
    method: 'PUT',
    body: JSON.stringify(branch),
  })
}

export function deleteBranch(id: string) {
  return request<{ id: string }>(`/api/admin/branches/${encodeURIComponent(id)}`, { method: 'DELETE' })
}

export function listCoupons() {
  return request<Coupon[]>('/api/admin/coupons')
}

export function createCoupon(coupon: Coupon) {
  return request<Coupon>('/api/admin/coupons', {
    method: 'POST',
    body: JSON.stringify(coupon),
  })
}

export function updateCoupon(coupon: Coupon, previousCode?: string) {
  return request<Coupon>(`/api/admin/coupons/${encodeURIComponent(previousCode ?? coupon.code)}`, {
    method: 'PUT',
    body: JSON.stringify({ ...coupon, previousCode }),
  })
}

export function deleteCoupon(code: string) {
  return request<{ code: string }>(`/api/admin/coupons/${encodeURIComponent(code)}`, { method: 'DELETE' })
}

export function listNotices() {
  return request<Notice[]>('/api/admin/notices')
}

export function createNotice(notice: Notice) {
  return request<Notice>('/api/admin/notices', {
    method: 'POST',
    body: JSON.stringify(notice),
  })
}

export function updateNotice(notice: Notice) {
  return request<Notice>(`/api/admin/notices/${encodeURIComponent(notice.id)}`, {
    method: 'PUT',
    body: JSON.stringify(notice),
  })
}

export function deleteNotice(id: string) {
  return request<{ id: string }>(`/api/admin/notices/${encodeURIComponent(id)}`, { method: 'DELETE' })
}

export function restoreDesk() {
  return request<{ branches: Branch[]; notices: Notice[]; coupons: Coupon[] }>('/api/admin/restore', {
    method: 'POST',
  })
}

export function getAdminProfile() {
  return request<AdminProfile>('/api/admin/profile')
}

export function updateAdminProfile(profile: AdminProfile) {
  return request<AdminProfile>('/api/admin/profile', {
    method: 'PATCH',
    body: JSON.stringify(profile),
  })
}

export function requestAdminOtp(phone: string) {
  return request<{ code: string }>('/api/admin/otp/request', {
    method: 'POST',
    body: JSON.stringify({ phone }),
  })
}

export function verifyAdminOtp(phone: string, code: string) {
  return request<{ profile: AdminProfile }>('/api/admin/otp/verify', {
    method: 'POST',
    body: JSON.stringify({ phone, code }),
  })
}
