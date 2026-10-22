import { useState, type FormEvent } from 'react'
import { Field, FormError, Modal, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import type { Notice, NoticeKind } from '../types'

const empty = (): Notice => ({
  id: `n${Date.now().toString().slice(-6)}`,
  title: '',
  body: '',
  timeLabel: 'Today',
  kind: 'info',
  targetId: '',
})

const kindLabel: Record<NoticeKind, string> = {
  info: 'Shop message',
  offer: 'Offer',
  product: 'Product',
  order: 'Order',
}

export function NoticesPage() {
  const { data, saveNotice, deleteNotice } = useStore()
  const [editing, setEditing] = useState<Notice | null>(null)

  return (
    <>
      <PageHeader title="Notices" lede="Messages on the shop notifications screen. An offer applies its coupon. A product or order opens that page.">
        <button type="button" className="btn primary" onClick={() => setEditing(empty())}>New notice</button>
      </PageHeader>
      <div className="stack-cards">
        {data.notices.map((notice) => (
          <article className="card notice" key={notice.id}>
            <div>
              <p className="kicker">{kindLabel[notice.kind] ?? 'Shop message'} · {notice.timeLabel}</p>
              <h2>{notice.title}</h2>
              <p>{notice.body}</p>
              {notice.targetId ? <p className="kicker">{notice.targetId}</p> : null}
            </div>
            <div className="actions">
              <button type="button" className="btn small ghost" onClick={() => setEditing(notice)}>Edit</button>
              <button type="button" className="btn small danger" onClick={() => { if (window.confirm('Remove this notice?')) deleteNotice(notice.id) }}>Remove</button>
            </div>
          </article>
        ))}
      </div>
      {editing ? (
        <NoticeForm
          notice={editing}
          onClose={() => setEditing(null)}
          onSave={async (notice) => {
            const problem = await saveNotice(notice)
            if (!problem) setEditing(null)
            return problem
          }}
        />
      ) : null}
    </>
  )
}

function NoticeForm({
  notice,
  onClose,
  onSave,
}: {
  notice: Notice
  onClose: () => void
  onSave: (notice: Notice) => Promise<string | null>
}) {
  const [draft, setDraft] = useState(notice)
  const [error, setError] = useState('')

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (draft.title.trim().length < 2 || draft.body.trim().length < 2) {
      return setError('Enter a title and a message.')
    }
    if (draft.kind !== 'info' && draft.targetId.trim().length < 2) {
      return setError(draft.kind === 'offer'
        ? 'Enter the coupon code this notice should apply.'
        : draft.kind === 'product'
          ? 'Enter the product id this notice should open.'
          : 'Enter the order id this notice should open.')
    }
    const problem = await onSave({
      ...draft,
      title: draft.title.trim(),
      body: draft.body.trim(),
      timeLabel: draft.timeLabel.trim() || 'Today',
      kind: draft.kind,
      targetId: draft.kind === 'info' ? '' : draft.targetId.trim(),
    })
    if (problem) setError(problem)
  }

  return (
    <Modal title={notice.title ? 'Edit notice' : 'New notice'} onClose={onClose}>
      <form onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Title" wide>
            <input value={draft.title} onChange={(event) => setDraft({ ...draft, title: event.target.value })} />
          </Field>
          <Field label="When">
            <input value={draft.timeLabel} onChange={(event) => setDraft({ ...draft, timeLabel: event.target.value })} />
          </Field>
          <Field label="Opens">
            <select
              value={draft.kind}
              onChange={(event) => setDraft({ ...draft, kind: event.target.value as NoticeKind })}
            >
              <option value="info">Shop message</option>
              <option value="offer">Offer</option>
              <option value="product">Product</option>
              <option value="order">Order</option>
            </select>
          </Field>
          {draft.kind === 'offer' ? (
            <Field label="Coupon code">
              <input value={draft.targetId} onChange={(event) => setDraft({ ...draft, targetId: event.target.value.toUpperCase() })} />
            </Field>
          ) : null}
          {draft.kind === 'product' ? (
            <Field label="Product id">
              <input value={draft.targetId} onChange={(event) => setDraft({ ...draft, targetId: event.target.value })} />
            </Field>
          ) : null}
          {draft.kind === 'order' ? (
            <Field label="Order id">
              <input value={draft.targetId} onChange={(event) => setDraft({ ...draft, targetId: event.target.value })} />
            </Field>
          ) : null}
          <Field label="Message" wide>
            <textarea rows={4} value={draft.body} onChange={(event) => setDraft({ ...draft, body: event.target.value })} />
          </Field>
        </div>
        <FormError message={error} />
        <div className="actions">
          <button type="button" className="btn ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn primary">Save notice</button>
        </div>
      </form>
    </Modal>
  )
}
