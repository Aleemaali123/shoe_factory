export type OrderStatus =
  | 'confirmed'
  | 'preparing'
  | 'onTheWay'
  | 'completed'
  | 'cancelled'

export type StockFilter = 'all' | 'in' | 'low' | 'out' | 'hidden'

export const photoPositions = ['Front', 'Side', 'Back', 'Top', 'Sole', 'Heel', 'Detail'] as const

export type ProductImage = {
  url: string
  position: string
}

export type Product = {
  id: string
  name: string
  category: string
  price: number
  oldPrice: number
  rating: number
  reviewCount: number
  imageUrl: string
  images: ProductImage[]
  description: string
  badge?: string
  colors: string[]
  sizes: number[]
  stock: number
  isNew: boolean
  listed: boolean
}

export function productPhotos(product: Pick<Product, 'imageUrl' | 'images'>): ProductImage[] {
  if (Array.isArray(product.images) && product.images.length > 0) {
    return product.images.filter((image) => image?.url?.trim())
  }
  if (product.imageUrl) return [{ url: product.imageUrl, position: 'Front' }]
  return []
}

export type OrderLine = {
  productId: string
  name: string
  imageUrl: string
  unitPrice: number
  color: string
  size: number
  quantity: number
}

export type Order = {
  id: string
  placedAt: string
  lines: OrderLine[]
  subtotal: number
  discount: number
  deliveryFee: number
  total: number
  fulfilment: 'delivery' | 'pickup'
  paymentMethod: 'razorpay' | 'upi' | 'card' | 'cod'
  status: OrderStatus
  destination: string
  contactName: string
  contactPhone: string
  customerId: string
  branchId: string
  couponCode?: string
}

export type Customer = {
  id: string
  name: string
  email: string
  phone: string
  city: string
  joinedAt: string
}

export type Branch = {
  id: string
  name: string
  address: string
  hours: string
  phone: string
}

export type CouponKind = 'percent' | 'flat' | 'shipping'

export type Coupon = {
  code: string
  label: string
  kind: CouponKind
  value: number
  minSubtotal: number
  active: boolean
}

export type Notice = {
  id: string
  title: string
  body: string
  timeLabel: string
}

export type AdminData = {
  products: Product[]
  orders: Order[]
  customers: Customer[]
  branches: Branch[]
  coupons: Coupon[]
  notices: Notice[]
  revenueBackfill?: boolean
}

export const categories = ['Sneakers', 'Sports', 'Casual', 'Formal', 'Sandals']
