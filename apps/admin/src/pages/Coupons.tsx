import { useState, type FormEvent } from 'react'
import { Field, FormError, Modal, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import { formatRupees } from '../lib/format'
import type { Coupon, CouponKind } from '../types'

const empty = (): Coupon => ({
  code: '',
  label: '',
  kind: 'percent',
  value: 10,
  minSubtotal: 0,
  active: true,
})

export function CouponsPage() {
  const { data, saveCoupon, deleteCoupon } = useStore()
  const [editing, setEditing] = useState<{ coupon: Coupon; previous?: string } | null>(null)

  return (
    <>
      <PageHeader title="Coupons" lede="Codes the shop cart knows: TREND10, FACTORY200 and FREESHIP.">
        <button type="button" className="btn primary" onClick={() => setEditing({ coupon: empty() })}>
          Add a code
        </button>
      </PageHeader>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Code</th>
              <th>Offer</th>
              <th>Minimum</th>
              <th>Status</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {data.coupons.map((coupon) => (
              <tr key={coupon.code}>
                <td><strong>{coupon.code}</strong></td>
                <td>{coupon.kind === 'percent' ? `${coupon.value}% off` : coupon.kind === 'flat' ? `${formatRupees(coupon.value)} off` : 'Free delivery'}</td>
                <td>{coupon.minSubtotal ? formatRupees(coupon.minSubtotal) : 'None'}</td>
                <td>
                  <button type="button" className={coupon.active ? 'pill tone-good' : 'pill tone-ink'} onClick={() => saveCoupon({ ...coupon, active: !coupon.active }, coupon.code)}>
                    {coupon.active ? 'Active' : 'Paused'}
                  </button>
                </td>
                <td className="row-actions">
                  <button type="button" className="btn small ghost" onClick={() => setEditing({ coupon, previous: coupon.code })}>Edit</button>
                  <button type="button" className="btn small danger" onClick={() => { if (window.confirm(`Remove ${coupon.code}?`)) deleteCoupon(coupon.code) }}>Remove</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {editing ? (
        <CouponForm
          coupon={editing.coupon}
          previous={editing.previous}
          onClose={() => setEditing(null)}
          onSave={(coupon) => {
            if (saveCoupon(coupon, editing.previous)) setEditing(null)
          }}
        />
      ) : null}
    </>
  )
}

function CouponForm({
  coupon,
  previous,
  onClose,
  onSave,
}: {
  coupon: Coupon
  previous?: string
  onClose: () => void
  onSave: (coupon: Coupon) => void
}) {
  const [draft, setDraft] = useState(coupon)
  const [error, setError] = useState('')

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    const code = draft.code.trim().toUpperCase()
    if (!/^[A-Z0-9]{3,16}$/.test(code)) return setError('Use 3–16 letters or numbers.')
    onSave({
      ...draft,
      code,
      label: draft.label.trim() || code,
      value: draft.kind === 'shipping' ? 0 : Number(draft.value),
      minSubtotal: Math.max(0, Number(draft.minSubtotal) || 0),
    })
  }

  return (
    <Modal title={previous ?? 'Add a code'} onClose={onClose}>
      <form onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Code">
            <input value={draft.code} onChange={(event) => setDraft({ ...draft, code: event.target.value.toUpperCase() })} />
          </Field>
          <Field label="Kind">
            <select value={draft.kind} onChange={(event) => setDraft({ ...draft, kind: event.target.value as CouponKind })}>
              <option value="percent">Percent off</option>
              <option value="flat">Flat rupees off</option>
              <option value="shipping">Free delivery</option>
            </select>
          </Field>
          <Field label="Minimum subtotal">
            <input type="number" min={0} value={draft.minSubtotal} onChange={(event) => setDraft({ ...draft, minSubtotal: Number(event.target.value) })} />
          </Field>
          <Field label="Label" wide>
            <input value={draft.label} onChange={(event) => setDraft({ ...draft, label: event.target.value })} />
          </Field>
        </div>
        <FormError message={error} />
        <div className="actions">
          <button type="button" className="btn ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn primary">Save code</button>
        </div>
      </form>
    </Modal>
  )
}
