export type PriceQuote = {
  subtotal: number
  discount: number
  deliveryFee: number
  total: number
  couponCode?: string
}

const freeDeliveryThreshold = 4999
const standardDelivery = 49

const coupons = [
  { code: 'TREND10', percent: 10, flatOff: 0, freeShipping: false, minSubtotal: 0 },
  { code: 'FACTORY200', percent: 0, flatOff: 200, freeShipping: false, minSubtotal: 1999 },
  { code: 'FREESHIP', percent: 0, flatOff: 0, freeShipping: true, minSubtotal: 999 },
]

export function quote(subtotal: number, couponCode?: string, pickup = false): PriceQuote {
  const coupon = coupons.find((item) => item.code === couponCode?.trim().toUpperCase())
  let discount = 0
  let freeShipping = false
  let applied: string | undefined
  if (coupon && subtotal >= coupon.minSubtotal) {
    if (coupon.percent > 0) discount += Math.round((subtotal * coupon.percent) / 100)
    if (coupon.flatOff > 0) discount += coupon.flatOff
    freeShipping = coupon.freeShipping
    applied = coupon.code
  }
  if (discount > subtotal) discount = subtotal
  const delivery =
    pickup || subtotal <= 0 || freeShipping || subtotal >= freeDeliveryThreshold
      ? 0
      : standardDelivery
  return {
    subtotal,
    discount,
    deliveryFee: delivery,
    total: Math.max(0, subtotal - discount + delivery),
    couponCode: applied,
  }
}
