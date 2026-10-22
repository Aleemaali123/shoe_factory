import { productPhotos, type Product } from '../types'

const base = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, '') || 'http://127.0.0.1:4000'

function asProduct(raw: Product): Product {
  const images = productPhotos(raw)
  return {
    ...raw,
    images,
    imageUrl: images[0]?.url ?? '',
    listed: raw.listed !== false,
    badge: raw.badge || undefined,
    colors: raw.colors ?? [],
    sizes: raw.sizes ?? [],
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
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
    throw new Error('The product API is not reachable. Start the shop API, then try again.')
  }
  const body = (await response.json().catch(() => ({}))) as { data?: T; error?: string }
  if (!response.ok) throw new Error(body.error || 'The product API could not complete that request.')
  return body.data as T
}

export function listProducts() {
  return request<Product[]>('/api/admin/products').then((products) => products.map(asProduct))
}

export function createProduct(product: Product) {
  return request<Product>('/api/admin/products', {
    method: 'POST',
    body: JSON.stringify(product),
  }).then(asProduct)
}

export function updateProduct(product: Product) {
  return request<Product>(`/api/admin/products/${encodeURIComponent(product.id)}`, {
    method: 'PUT',
    body: JSON.stringify(product),
  }).then(asProduct)
}

export function adjustProductStock(id: string, delta: number) {
  return request<Product>(`/api/admin/products/${encodeURIComponent(id)}/stock`, {
    method: 'PATCH',
    body: JSON.stringify({ delta }),
  }).then(asProduct)
}

export function removeProduct(id: string) {
  return request<{ id: string; name: string }>(`/api/admin/products/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  })
}
