import { useState, type FormEvent } from 'react'
import { Field, FormError, Modal, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import type { Branch } from '../types'

const empty = (): Branch => ({
  id: '',
  name: '',
  address: '',
  hours: 'Open today · 10:00 AM–9:00 PM',
  phone: '',
})

export function BranchesPage() {
  const { data, saveBranch, deleteBranch } = useStore()
  const [editing, setEditing] = useState<Branch | null>(null)

  return (
    <>
      <PageHeader title="Branches" lede="Stores shoppers can collect from.">
        <button type="button" className="btn primary" onClick={() => setEditing(empty())}>
          Add a branch
        </button>
      </PageHeader>
      <div className="cards">
        {data.branches.map((branch) => {
          const open = data.orders.filter(
            (order) => order.branchId === branch.id && order.status !== 'completed' && order.status !== 'cancelled',
          ).length
          return (
            <article className="card branch" key={branch.id}>
              <p className="kicker">{branch.id}</p>
              <h2>{branch.name}</h2>
              <p>{branch.address}</p>
              <p className="muted">{branch.hours}</p>
              <p>{branch.phone}</p>
              <p className="muted">{open === 0 ? 'No open orders' : `${open} open ${open === 1 ? 'order' : 'orders'}`}</p>
              <div className="actions">
                <button type="button" className="btn small ghost" onClick={() => setEditing(branch)}>Edit</button>
                <button
                  type="button"
                  className="btn small danger"
                  onClick={() => {
                    if (window.confirm(`Remove ${branch.name}?`)) deleteBranch(branch.id)
                  }}
                >
                  Remove
                </button>
              </div>
            </article>
          )
        })}
      </div>
      {editing ? (
        <BranchForm
          branch={editing}
          lockedId={Boolean(editing.id)}
          onClose={() => setEditing(null)}
          onSave={(branch) => {
            if (saveBranch(branch, !editing.id)) setEditing(null)
          }}
        />
      ) : null}
    </>
  )
}

function BranchForm({
  branch,
  lockedId,
  onClose,
  onSave,
}: {
  branch: Branch
  lockedId: boolean
  onClose: () => void
  onSave: (branch: Branch) => void
}) {
  const [draft, setDraft] = useState(branch)
  const [error, setError] = useState('')

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    const id = (draft.id || draft.name.toLowerCase().replace(/[^a-z0-9]+/g, '').slice(0, 10)).trim().toLowerCase()
    if (!draft.name.trim() || !id || !draft.address.trim() || !draft.phone.trim()) {
      return setError('Add a name, address and phone number.')
    }
    onSave({ ...draft, id, name: draft.name.trim(), address: draft.address.trim(), phone: draft.phone.trim() })
  }

  return (
    <Modal title={branch.name || 'Add a branch'} onClose={onClose}>
      <form onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Name" wide>
            <input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </Field>
          <Field label="Id">
            <input value={draft.id} disabled={lockedId} onChange={(event) => setDraft({ ...draft, id: event.target.value })} />
          </Field>
          <Field label="Phone">
            <input value={draft.phone} onChange={(event) => setDraft({ ...draft, phone: event.target.value })} />
          </Field>
          <Field label="Address" wide>
            <input value={draft.address} onChange={(event) => setDraft({ ...draft, address: event.target.value })} />
          </Field>
          <Field label="Hours" wide>
            <input value={draft.hours} onChange={(event) => setDraft({ ...draft, hours: event.target.value })} />
          </Field>
        </div>
        <FormError message={error} />
        <div className="actions">
          <button type="button" className="btn ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn primary">Save branch</button>
        </div>
      </form>
    </Modal>
  )
}
