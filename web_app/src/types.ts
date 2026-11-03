export type SortKey = 'featured' | 'priceLow' | 'priceHigh' | 'rating' | 'newest'

export type OrderStatus = 'confirmed' | 'preparing' | 'onTheWay' | 'completed' | 'cancelled'

export type Fulfilment = 'delivery' | 'pickup'

export type PaymentMethod = 'razorpay' | 'cod'

export type ProductImage = {
  url: string
  position?: string
  color?: string
}

export type Review = {
  author: string
  rating: number
  comment: string
}

export type Product = {
  id: string
  name: string
  category: string
  price: number
  oldPrice: number
  rating: number
  reviewCount: number
  imageUrls: string[]
  images: ProductImage[]
  description: string
  badge: string | null
  colors: string[]
  sizes: number[]
  stock: number
  isNew: boolean
  reviews: Review[]
}

export type CartItem = {
  id: string
  productId: string
  name: string
  imageUrl: string
  unitPrice: number
  color: string
  size: number
  quantity: number
}

export type Cart = {
  items: CartItem[]
  couponCode: string | null
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
  fulfilment: string
  paymentMethod: string
  status: OrderStatus
  destination: string
  contactName: string
  contactPhone: string
  couponCode?: string | null
  paymentReference?: string | null
  customerMessage?: string | null
  trackingUrl?: string | null
  whatsappComposeUrl?: string | null
}

export type Address = {
  id: string
  label: string
  name: string
  phone: string
  line: string
  city: string
  pincode: string
  isDefault: boolean
}

export type User = {
  name: string
  email: string
  phone: string
}

export type Branch = {
  id: string
  name: string
  address: string
  hours: string
  phone: string
}

export type Notice = {
  id: string
  title: string
  body: string
  timeLabel: string
  read: boolean
  kind: string
  targetId: string
}

export type Coupon = {
  code: string
  label: string
  percent: number
  flatOff: number
  freeShipping: boolean
  minSubtotal: number
}

export type Quote = {
  subtotal: number
  discount: number
  deliveryFee: number
  total: number
  couponCode: string | null
  couponLabel: string | null
}

export type Profile = {
  user: User | null
  addresses: Address[]
}

export type Session = Profile & {
  token?: string
  cart: Cart
  wishlist: string[]
  orders: Order[]
  notices: Notice[]
  branches: Branch[]
  coupons: Coupon[]
  products: Product[]
  categories: string[]
}
