import { useState, type FormEvent } from 'react'
import { Field, FormError, Modal, PageHeader } from '../components/ui'
import { useStore } from '../data/store'
import { formatRupees, formatWhen } from '../lib/format'
import type { Customer } from '../types'

export function CustomersPage() {
  const { data, saveCustomer } = useStore()
  const [editing, setEditing] = useState<Customer | null>(null)
  const rows = [...data.customers].sort((a, b) => a.name.localeCompare(b.name))

  return (
    <>
      <PageHeader title="Customers" lede="Shoppers attached to the demo orders." />
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Contact</th>
              <th>City</th>
              <th className="num">Orders</th>
              <th className="num">Spent</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {rows.map((customer) => {
              const orders = data.orders.filter((order) => order.customerId === customer.id && order.status !== 'cancelled')
              const spent = orders.reduce((sum, order) => sum + order.total, 0)
              return (
                <tr key={customer.id}>
                  <td>
                    <strong>{customer.name}</strong>
                    <small className="block">Joined {formatWhen(customer.joinedAt)}</small>
                  </td>
                  <td>
                    {customer.email}
                    <small className="block">{customer.phone}</small>
                  </td>
                  <td>{customer.city}</td>
                  <td className="num">{orders.length}</td>
                  <td className="num">{formatRupees(spent)}</td>
                  <td className="row-actions">
                    <button type="button" className="btn small ghost" onClick={() => setEditing(customer)}>
                      Edit
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
      {editing ? (
        <CustomerForm
          customer={editing}
          onClose={() => setEditing(null)}
          onSave={(customer) => {
            saveCustomer(customer)
            setEditing(null)
          }}
        />
      ) : null}
    </>
  )
}

function CustomerForm({
  customer,
  onClose,
  onSave,
}: {
  customer: Customer
  onClose: () => void
  onSave: (customer: Customer) => void
}) {
  const [draft, setDraft] = useState(customer)
  const [error, setError] = useState('')

  function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (!draft.name.trim()) return setError('Enter a name.')
    if (!draft.email.includes('@')) return setError('Enter an email.')
    onSave({ ...draft, name: draft.name.trim(), email: draft.email.trim(), phone: draft.phone.trim(), city: draft.city.trim() })
  }

  return (
    <Modal title={customer.name} onClose={onClose}>
      <form onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Name" wide>
            <input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} />
          </Field>
          <Field label="Email">
            <input value={draft.email} onChange={(event) => setDraft({ ...draft, email: event.target.value })} />
          </Field>
          <Field label="Phone">
            <input value={draft.phone} onChange={(event) => setDraft({ ...draft, phone: event.target.value })} />
          </Field>
          <Field label="City" wide>
            <input value={draft.city} onChange={(event) => setDraft({ ...draft, city: event.target.value })} />
          </Field>
        </div>
        <FormError message={error} />
        <div className="actions">
          <button type="button" className="btn ghost" onClick={onClose}>Cancel</button>
          <button type="submit" className="btn primary">Save customer</button>
        </div>
      </form>
    </Modal>
  )
}
