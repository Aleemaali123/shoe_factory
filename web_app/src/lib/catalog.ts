import type { Coupon, Product, Quote, SortKey } from '../types'

export const sorts: { id: SortKey; label: string }[] = [
  { id: 'featured', label: 'Featured' },
  { id: 'priceLow', label: 'Price: low to high' },
  { id: 'priceHigh', label: 'Price: high to low' },
  { id: 'rating', label: 'Top rated' },
  { id: 'newest', label: 'New arrivals' },
]

const swatches: Record<string, string> = {
  Green: '#00C52B',
  Black: '#1A1A1A',
  White: '#F4F4F4',
  Red: '#D32F2F',
  Navy: '#1A237E',
  Brown: '#6D4C41',
  Grey: '#B0B6B0',
  Beige: '#E6D3B3',
  Blue: '#1565C0',
  Pink: '#EC407A',
  Yellow: '#FBC02D',
  Orange: '#EF6C00',
  Purple: '#6A1B9A',
}

export function shoeColor(name: string) {
  return swatches[name] ?? '#777D78'
}

export function discountPercent(product: Pick<Product, 'price' | 'oldPrice'>) {
  if (product.oldPrice <= product.price) return 0
  return Math.round(((product.oldPrice - product.price) / product.oldPrice) * 100)
}

export function coverImage(product: Product, color = '') {
  return galleryFor(product, color)[0] ?? ''
}

export function galleryFor(product: Product, color: string) {
  const photos = product.images.filter((image) => image.url)
  const urls = product.imageUrls.filter(Boolean)
  if (!color || photos.every((image) => !image.color)) {
    return urls.length ? urls : photos.map((image) => image.url)
  }
  const match = photos
    .filter((image) => image.color?.toLowerCase() === color.toLowerCase())
    .map((image) => image.url)
  const shared = photos.filter((image) => !image.color).map((image) => image.url)
  if (match.length) return [...match, ...shared]
  return urls.length ? urls : photos.map((image) => image.url)
}

export function sizeHeading(category: string) {
  if (category === 'Watches') return 'Case size'
  if (category === 'Perfumes') return 'Volume'
  if (category === 'Caps') return 'Head size'
  return 'Size (UK)'
}

export function sizeOption(category: string, size: number) {
  if (category === 'Watches') return `${size} mm`
  if (category === 'Perfumes') return `${size} ml`
  if (category === 'Caps') return `${size} cm`
  return `UK ${size}`
}

export function sizeGuide(category: string) {
  if (category === 'Watches') {
    return 'Case size is the width of the watch face in millimetres. 40 mm wears smaller and 42 mm wears larger.'
  }
  if (category === 'Perfumes') {
    return 'Volume is the bottle size in millilitres. 50 ml is easy to carry. 100 ml is the full bottle.'
  }
  if (category === 'Caps') {
    return 'Head size is the circumference in centimetres. If you are between sizes, choose the larger one.'
  }
  if (category === 'Socks') return 'Sock size follows your usual UK shoe size.'
  return 'Choose your usual UK size. If you are between sizes, the next size up is the safer fit for sneakers and boots.'
}

function featuredRank(product: Product) {
  return Math.round(product.rating * 10) + (product.badge ? 20 : 0)
}

export function sortProducts(products: Product[], sort: SortKey) {
  return [...products].sort((a, b) => {
    if (sort === 'priceLow') return a.price - b.price
    if (sort === 'priceHigh') return b.price - a.price
    if (sort === 'rating') return b.rating - a.rating
    if (sort === 'newest') {
      if (a.isNew !== b.isNew) return a.isNew ? -1 : 1
      return b.rating - a.rating
    }
    return featuredRank(b) - featuredRank(a)
  })
}

export function filterProducts(products: Product[], query: string, category: string) {
  const needle = query.trim().toLowerCase()
  return products.filter((product) => {
    if (category && category !== 'All' && product.category !== category) return false
    if (!needle) return true
    const haystack = `${product.name} ${product.category} ${product.description} ${product.colors.join(' ')}`.toLowerCase()
    return haystack.includes(needle)
  })
}

export function lineTotal(unitPrice: number, quantity: number) {
  return unitPrice * quantity
}

export function cartSubtotal(items: { unitPrice: number; quantity: number }[]) {
  return items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0)
}

export function quoteLocal(subtotal: number, couponCode: string | null, pickup: boolean, coupons: Coupon[]): Quote {
  const coupon = coupons.find((item) => item.code === (couponCode ?? '').toUpperCase())
  let discount = 0
  let freeShipping = false
  let appliedCode: string | null = null
  let appliedLabel: string | null = null
  if (coupon && subtotal >= coupon.minSubtotal) {
    if (coupon.percent > 0) discount += Math.round((subtotal * coupon.percent) / 100)
    if (coupon.flatOff > 0) discount += coupon.flatOff
    freeShipping = coupon.freeShipping
    appliedCode = coupon.code
    appliedLabel = coupon.label
  }
  if (discount > subtotal) discount = subtotal
  const deliveryFee = pickup || subtotal <= 0 || freeShipping || subtotal >= 4999 ? 0 : 49
  return {
    subtotal,
    discount,
    deliveryFee,
    total: Math.max(0, subtotal - discount + deliveryFee),
    couponCode: appliedCode,
    couponLabel: appliedLabel,
  }
}
