import { useTitle } from '../components/ui'

const sections = [
  ['Returns', 'Unworn shoes in original packaging can be returned within 7 days. Sale items can be exchanged for size, subject to stock.'],
  ['Shipping', 'Delivery is ₹49, and free when the cart is ₹4,999 or more. Store pickup is always free. Most Kerala orders arrive in 2–4 days.'],
  ['Privacy', 'Your name, phone, addresses and orders are stored with your Shoe Factory account and used to fulfil orders. A shop session stays in this browser until you sign out.'],
  ['Terms', 'Prices are in Indian rupees and include the discounts shown on each pair. Online payment uses Razorpay test mode, so a successful demo payment is not a real charge or a binding sale.'],
]

export function PoliciesPage() {
  useTitle('Policies')
  return (
    <section style={{ maxWidth: 760 }}>
      <div className="section-head">
        <h2>Policies</h2>
      </div>
      {sections.map(([title, body]) => (
        <article key={title} className="policy" style={{ marginBottom: 12 }}>
          <h3>{title}</h3>
          <p className="muted">{body}</p>
        </article>
      ))}
    </section>
  )
}
