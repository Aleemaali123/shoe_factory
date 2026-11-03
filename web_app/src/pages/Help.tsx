import { useTitle } from '../components/ui'
import { useShop } from '../data/shop'

export function HelpPage() {
  useTitle('Help')
  const shop = useShop()
  const couponAnswer = shop.coupons.length
    ? shop.coupons.map((coupon) => `${coupon.code}: ${coupon.label}`).join(' ')
    : 'There are no coupon codes right now.'
  const faqs = [
    ['How long does delivery take?', 'Home delivery in Kerala usually arrives in 2–4 days. Store pickup is ready in 1–2 days.'],
    ['Can I collect from a branch?', 'Yes. Choose store pickup at checkout and the order is marked ready for collection.'],
    ['How do returns work?', 'Unworn shoes can be returned within 7 days of delivery or collection, with the original packaging.'],
    ['Which coupon codes work?', couponAnswer],
    ['Is payment live?', 'Pay online uses Razorpay test checkout when the backend has Razorpay test keys in its .env file. Cards: 5267 3181 8797 5449, or UPI success@razorpay. Cash on delivery is collected later.'],
    ['Will I get a WhatsApp update?', 'After a successful online payment we send a WhatsApp confirmation with a tracking link to the mobile number on the order. You can also open Track order from this site.'],
  ]

  return (
    <section style={{ maxWidth: 760 }}>
      <div className="help-hero">
        <h2>We are here to help</h2>
        <p>hello@shoefactory.shop</p>
        <p>0471 555 0100 · 10:00 AM–9:00 PM</p>
      </div>
      {faqs.map(([question, answer]) => (
        <details key={question} className="faq" style={{ marginBottom: 10 }}>
          <summary>{question}</summary>
          <p>{answer}</p>
        </details>
      ))}
    </section>
  )
}
