import { useState, type FormEvent } from 'react'
import { Field, FormError, Modal, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import type { Notice } from '../types'

const empty = (): Notice => ({
  id: `n${Date.now().toString().slice(-6)}`,
  title: '',
  body: '',
  timeLabel: 'Today',
})

export function NoticesPage() {
  const { data, saveNotice, deleteNotice } = useStore()
  const [editing, setEditing] = useState<Notice | null>(null)

  return (
    <>
      <PageHeader title="Notices" lede="Messages that show on the shop notifications screen.">
        <button type="button" className="btn primary" onClick={() => setEditing(empty())}>New notice</button>
      </PageHeader>
      <div className="stack-cards">
        {data.notices.map((notice) => (
          <article className="card notice" key={notice.id}>
            <div>
              <p className="kicker">{notice.timeLabel}</p>
              <h2>{notice.title}</h2>
              <p>{notice.body}</p>
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
          onSave={(notice) => {
            saveNotice(notice)
            setEditing(null)
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
  onSave: (notice: Notice) => void
}) {
  const [draft, setDraft] = useState(notice)
  const [error, setError] = useState('')

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (!draft.title.trim() || !draft.body.trim()) return setError('Enter a title and a message.')
    onSave({ ...draft, title: draft.title.trim(), body: draft.body.trim(), timeLabel: draft.timeLabel.trim() || 'Today' })
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
