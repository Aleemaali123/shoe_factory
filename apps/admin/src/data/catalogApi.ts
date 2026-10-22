import { request } from './api'
import { productPhotos, type Product } from '../types'

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
