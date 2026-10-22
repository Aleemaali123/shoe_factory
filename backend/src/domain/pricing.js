export const freeDeliveryThreshold = 4999;
export const standardDelivery = 49;

export const coupons = [
  { code: 'TREND10', label: '10% off', percent: 10, flatOff: 0, freeShipping: false, minSubtotal: 0 },
  { code: 'FACTORY200', label: '₹200 off above ₹1,999', percent: 0, flatOff: 200, freeShipping: false, minSubtotal: 1999 },
  { code: 'FREESHIP', label: 'Free delivery above ₹999', percent: 0, flatOff: 0, freeShipping: true, minSubtotal: 999 },
];

export function findCoupon(code) {
  if (!code || !String(code).trim()) return null;
  const key = String(code).trim().toUpperCase();
  return coupons.find((coupon) => coupon.code === key) ?? null;
}

function deliveryFee({ subtotal, pickup, freeShipping }) {
  if (pickup || subtotal <= 0) return 0;
  if (freeShipping || subtotal >= freeDeliveryThreshold) return 0;
  return standardDelivery;
}

export function calculate({ subtotal, couponCode, pickup }) {
  const coupon = findCoupon(couponCode);
  let discount = 0;
  let freeShipping = false;
  let appliedCode;
  let appliedLabel;
  if (coupon && subtotal >= coupon.minSubtotal) {
    if (coupon.percent > 0) discount += Math.round((subtotal * coupon.percent) / 100);
    if (coupon.flatOff > 0) discount += coupon.flatOff;
    freeShipping = coupon.freeShipping;
    appliedCode = coupon.code;
    appliedLabel = coupon.label;
  }
  if (discount > subtotal) discount = subtotal;
  const delivery = deliveryFee({ subtotal, pickup, freeShipping });
  const total = Math.max(0, subtotal - discount + delivery);
  return {
    subtotal,
    discount,
    deliveryFee: delivery,
    total,
    couponCode: appliedCode ?? null,
    couponLabel: appliedLabel ?? null,
  };
}

export function evaluate({ subtotal, rawCode, pickup }) {
  const code = String(rawCode ?? '').trim().toUpperCase();
  const plain = calculate({ subtotal, pickup });
  if (!code) {
    return { accepted: false, message: 'Enter a coupon code.', quote: plain };
  }
  const coupon = findCoupon(code);
  if (!coupon) {
    return {
      accepted: false,
      message: 'That code is not recognised. Try TREND10, FACTORY200 or FREESHIP.',
      quote: plain,
    };
  }
  if (subtotal < coupon.minSubtotal) {
    return {
      accepted: false,
      message: `Add a little more to your cart to use ${coupon.code}.`,
      quote: plain,
    };
  }
  const quote = calculate({ subtotal, couponCode: code, pickup });
  const message = pickup && coupon.freeShipping
    ? `Store pickup is already free. ${coupon.code} is saved on this order.`
    : `${coupon.code} applied. ${coupon.label}.`;
  return { accepted: true, message, quote };
}
