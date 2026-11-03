import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Empty, Field, Money, useTitle } from '../components/ui'
import { quote as quoteOrder } from '../data/api'
import { useShop } from '../data/shop'
import { payWithRazorpay, usesDemoOnlinePayment } from '../lib/razorpay'
import { deliveryFeeLabel, formatRupees } from '../lib/format'
import type { Fulfilment, PaymentMethod, Quote } from '../types'

const blankQuote: Quote = {
  subtotal: 0,
  discount: 0,
  deliveryFee: 0,
  total: 0,
  couponCode: null,
  couponLabel: null,
}

export function CheckoutPage() {
  useTitle('Checkout')
  const shop = useShop()
  const navigate = useNavigate()
  const branch = shop.branches.find((item) => item.id === shop.branchId) ?? shop.branches[0]
  const [fulfilment, setFulfilment] = useState<Fulfilment>('delivery')
  const [payment, setPayment] = useState<PaymentMethod>('cod')
  const [name, setName] = useState(shop.user?.name ?? '')
  const [phone, setPhone] = useState(shop.user?.phone ?? '')
  const [line, setLine] = useState('')
  const [city, setCity] = useState('')
  const [pincode, setPincode] = useState('')
  const [quote, setQuote] = useState<Quote>(blankQuote)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [testPay, setTestPay] = useState<{ amountPaise: number; description: string } | null>(null)
  const testPayWaiter = useRef<{ resolve: (value: boolean) => void } | null>(null)

  useEffect(() => {
    shop.clearFlash()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    const chosen = shop.addresses.find((item) => item.isDefault) ?? shop.addresses[0]
    if (!chosen) return
    setName((current) => current || chosen.name)
    setPhone((current) => current || chosen.phone)
    setLine((current) => current || chosen.line)
    setCity((current) => current || chosen.city)
    setPincode((current) => current || chosen.pincode)
  }, [shop.addresses])

  useEffect(() => {
    let cancelled = false
    quoteOrder(fulfilment).then(
      (next) => {
        if (!cancelled) setQuote(next)
      },
      (caught: unknown) => {
        if (!cancelled) setError(caught instanceof Error ? caught.message : 'Could not price this order.')
      },
    )
    return () => {
      cancelled = true
    }
  }, [fulfilment, shop.cart.couponCode, shop.cart.items])

  useEffect(() => {
    return () => {
      testPayWaiter.current?.resolve(false)
      testPayWaiter.current = null
    }
  }, [])

  if (!shop.cart.items.length) {
    return <Empty title="Nothing to check out" body="Your cart is empty." action="Browse the shop" to="/shop" />
  }

  const destination = fulfilment === 'pickup'
    ? [branch?.name, branch?.address].filter(Boolean).join(', ')
    : [line, city, pincode].filter(Boolean).join(', ')

  function askTestPayment(input: { amountPaise: number; description: string }) {
    return new Promise<boolean>((resolve) => {
      testPayWaiter.current?.resolve(false)
      testPayWaiter.current = { resolve }
      setTestPay(input)
    })
  }

  function finishTestPayment(ok: boolean) {
    const waiter = testPayWaiter.current
    testPayWaiter.current = null
    setTestPay(null)
    waiter?.resolve(ok)
  }

  async function place() {
    const contactPhone = phone.replace(/\D/g, '')
    if (name.trim().length < 2) return setError('Enter the recipient name.')
    if (contactPhone.length !== 10) return setError('Enter a 10-digit phone number.')
    if (destination.trim().length < 5) return setError(fulfilment === 'pickup' ? 'Choose a branch.' : 'Enter the delivery address.')
    setBusy(true)
    setError('')
    try {
      let paymentReference: string | undefined
      let razorpayOrderId: string | undefined
      let razorpaySignature: string | undefined
      if (payment === 'razorpay') {
        const description = shop.cart.items.length === 1
          ? shop.cart.items[0].name
          : `${shop.cart.items[0].name} + ${shop.cart.items.length - 1} more`
        const paid = await payWithRazorpay(
          {
            amountPaise: Math.round(quote.total * 100),
            phone: contactPhone,
            email: shop.user?.email ?? '',
            description,
          },
          { confirmTest: askTestPayment },
        )
        paymentReference = paid.paymentId
        razorpayOrderId = paid.orderId
        razorpaySignature = paid.signature
      }
      const order = await shop.placeOrder({
        fulfilment,
        paymentMethod: payment,
        contactName: name.trim(),
        contactPhone,
        destination,
        paymentReference,
        branchId: branch?.id,
        razorpayOrderId,
        razorpaySignature,
      })
      navigate(`/orders/${order.id}`, {
        state: {
          placed: true,
          message: order.customerMessage,
          trackingUrl: order.trackingUrl,
          paid: payment === 'razorpay',
        },
      })
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not place the order.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="layout">
      <section className="panel">
        <h2>Checkout</h2>
        <div className="choice">
          <strong>How should it arrive?</strong>
          <div className="chips">
            <button type="button" className={fulfilment === 'delivery' ? 'chip on' : 'chip'} onClick={() => setFulfilment('delivery')}>
              Home delivery
            </button>
            <button type="button" className={fulfilment === 'pickup' ? 'chip on' : 'chip'} onClick={() => setFulfilment('pickup')}>
              Store pickup · free
            </button>
          </div>
        </div>
        {fulfilment === 'pickup' ? (
          <div className="choice">
            <strong>Branch</strong>
            <div className="form">
              {shop.branches.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  className={item.id === branch?.id ? 'address on' : 'address'}
                  onClick={() => shop.setBranch(item.id)}
                >
                  <strong>{item.name}</strong>
                  <span>{item.address}</span>
                  <span className="muted">{item.hours}</span>
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="choice">
            <strong>Delivery address</strong>
            {!shop.user ? (
              <p className="muted">
                <Link to="/sign-in" state={{ from: '/checkout' }}>Sign in</Link> to use a saved address.
              </p>
            ) : null}
            {shop.addresses.length ? (
              <div className="form">
                {shop.addresses.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    className="address"
                    onClick={() => {
                      setName(item.name)
                      setPhone(item.phone)
                      setLine(item.line)
                      setCity(item.city)
                      setPincode(item.pincode)
                    }}
                  >
                    <strong>{item.label}{item.isDefault ? ' · default' : ''}</strong>
                    <span>{item.line}, {item.city} {item.pincode}</span>
                  </button>
                ))}
              </div>
            ) : null}
            <div className="form two">
              <Field label="Address line" value={line} onChange={(event) => setLine(event.target.value)} />
              <Field label="City" value={city} onChange={(event) => setCity(event.target.value)} />
              <Field label="Pincode" value={pincode} inputMode="numeric" onChange={(event) => setPincode(event.target.value)} />
            </div>
          </div>
        )}
        <div className="form two" style={{ marginTop: 16 }}>
          <Field label="Recipient name" value={name} onChange={(event) => setName(event.target.value)} />
          <Field label="Mobile number" value={phone} inputMode="numeric" onChange={(event) => setPhone(event.target.value)} />
        </div>
        <div className="choice">
          <strong>Payment</strong>
          <div className="chips">
            <button type="button" className={payment === 'cod' ? 'chip on' : 'chip'} onClick={() => setPayment('cod')}>
              Cash on delivery
            </button>
            <button type="button" className={payment === 'razorpay' ? 'chip on' : 'chip'} onClick={() => setPayment('razorpay')}>
              Pay online
            </button>
          </div>
          {payment === 'razorpay' ? (
            <p className="muted">
              {usesDemoOnlinePayment()
                ? 'Razorpay test mode. Confirm the amount on the next step — no real money moves.'
                : 'Razorpay test mode. Use card 4111 1111 1111 1111 or 5267 3181 8797 5449 (OTP 1111), or UPI success@razorpay. No real money moves.'}
            </p>
          ) : (
            <p className="muted">Pay when the pair arrives, or when you collect it.</p>
          )}
        </div>
        {error ? <p className="error">{error}</p> : null}
        <button className="btn primary" type="button" disabled={busy || Boolean(testPay)} onClick={() => void place()} style={{ marginTop: 8 }}>
          {busy
            ? 'Opening payment…'
            : payment === 'razorpay'
              ? `Pay online · ${formatRupees(quote.total)}`
              : `Place order · ${formatRupees(quote.total)}`}
        </button>
      </section>
      <aside className="panel">
        <h2>To pay</h2>
        {shop.cart.items.map((item) => (
          <p key={item.id} className="money">
            <span>{item.name} × {item.quantity}</span>
            <strong>{formatRupees(item.unitPrice * item.quantity)}</strong>
          </p>
        ))}
        <Money label="Subtotal" value={formatRupees(quote.subtotal)} />
        <Money label="Discount" value={quote.discount ? `-${formatRupees(quote.discount)}` : formatRupees(0)} />
        <Money label={fulfilment === 'pickup' ? 'Pickup' : 'Delivery'} value={deliveryFeeLabel(quote.deliveryFee, fulfilment === 'pickup', quote.subtotal)} />
        {quote.couponCode ? <p className="ok">{quote.couponCode} · {quote.couponLabel}</p> : null}
        <Money label="Total" value={formatRupees(quote.total)} total />
      </aside>

      {testPay ? (
        <div className="pay-modal" role="dialog" aria-modal="true" aria-labelledby="pay-modal-title">
          <div className="pay-modal-card">
            <h3 id="pay-modal-title">Razorpay test payment</h3>
            <p>{testPay.description}</p>
            <p className="pay-modal-amount">{formatRupees(testPay.amountPaise / 100)}</p>
            <p className="muted">Test mode — no real money is charged.</p>
            <div className="pay-modal-actions">
              <button type="button" className="btn ghost" onClick={() => finishTestPayment(false)}>
                Cancel
              </button>
              <button type="button" className="btn primary" onClick={() => finishTestPayment(true)}>
                Pay now
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  )
}
