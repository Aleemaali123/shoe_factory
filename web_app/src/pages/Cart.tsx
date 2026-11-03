import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Empty, Money, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import { quoteLocal, sizeOption } from '../lib/catalog'
import { deliveryFeeLabel, formatRupees } from '../lib/format'

export function CartPage() {
  useTitle('Cart')
  const shop = useShop()
  const [code, setCode] = useState(shop.cart.couponCode ?? '')
  const [message, setMessage] = useState('')
  const [accepted, setAccepted] = useState(false)
  const quote = quoteLocal(shop.subtotal, shop.cart.couponCode, false, shop.coupons)

  if (!shop.cart.items.length) {
    return <Empty title="Your cart is empty" body="Add a pair and it will wait here." action="Browse the shop" to="/shop" />
  }

  return (
    <div className="layout">
      <section className="panel">
        <h2>Cart</h2>
        {shop.cart.items.map((item) => (
          <div className="line" key={item.id}>
            <img src={item.imageUrl} alt="" />
            <div>
              <strong>
                <Link to={`/product/${item.productId}`}>{item.name}</Link>
              </strong>
              <p className="muted">
                {item.color} · {sizeOption(shop.products.find((product) => product.id === item.productId)?.category ?? '', item.size)}
              </p>
              <div className="stepper">
                <button
                  type="button"
                  aria-label="Decrease quantity"
                  onClick={() => {
                    if (item.quantity <= 1) void shop.removeItem(item.id)
                    else void shop.setQuantity(item.id, item.quantity - 1)
                  }}
                >
                  −
                </button>
                <span>{item.quantity}</span>
                <button
                  type="button"
                  aria-label="Increase quantity"
                  onClick={() => {
                    void shop.setQuantity(item.id, item.quantity + 1).then((cart) => {
                      const next = cart.items.find((line) => line.id === item.id)
                      if (next && next.quantity < item.quantity + 1) shop.note('That is the most available for this pair.')
                    })
                  }}
                >
                  +
                </button>
              </div>
            </div>
            <div className="end">
              <strong>{formatRupees(item.unitPrice * item.quantity)}</strong>
              <p>
                <button className="text-btn" type="button" onClick={() => void shop.removeItem(item.id)}>
                  Remove
                </button>
              </p>
            </div>
          </div>
        ))}
      </section>
      <aside className="panel">
        <h2>Summary</h2>
        <form
          className="coupon"
          style={{ margin: '12px 0' }}
          onSubmit={(event) => {
            event.preventDefault()
            void shop.applyCoupon(code, false).then(
              (result) => {
                setAccepted(result.accepted)
                setMessage(result.message)
              },
              (error: unknown) => {
                setAccepted(false)
                setMessage(error instanceof Error ? error.message : 'Could not apply that code.')
              },
            )
          }}
        >
          <input value={code} onChange={(event) => setCode(event.target.value.toUpperCase())} placeholder="Coupon code" aria-label="Coupon code" />
          <button className="btn line" type="submit">
            Apply
          </button>
        </form>
        {shop.cart.couponCode ? (
          <p>
            <button className="text-btn" type="button" onClick={() => void shop.clearCoupon().then(() => setMessage('Coupon removed.'))}>
              Remove {shop.cart.couponCode}
            </button>
          </p>
        ) : null}
        {message ? <p className={accepted ? 'ok' : 'error'}>{message}</p> : null}
        <p className="muted">Try {shop.coupons.map((coupon) => coupon.code).join(', ') || 'a code from the shop'}.</p>
        <Money label="Subtotal" value={formatRupees(quote.subtotal)} />
        <Money label="Discount" value={quote.discount ? `-${formatRupees(quote.discount)}` : formatRupees(0)} />
        <Money label="Delivery" value={deliveryFeeLabel(quote.deliveryFee, false, quote.subtotal)} />
        <Money label="Total" value={formatRupees(quote.total)} total />
        <Link className="btn primary block" to="/checkout" style={{ marginTop: 14, display: 'block', textAlign: 'center' }}>
          Checkout
        </Link>
      </aside>
    </div>
  )
}
