import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { Field, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import type { Address } from '../types'

const emptyAddress = { label: 'Home', name: '', phone: '', line: '', city: '', pincode: '' }

export function AccountPage() {
  useTitle('Account')
  const shop = useShop()
  const [name, setName] = useState(shop.user?.name ?? '')
  const [email, setEmail] = useState(shop.user?.email ?? '')
  const [phone, setPhone] = useState(shop.user?.phone ?? '')
  const [address, setAddress] = useState(emptyAddress)
  const [editing, setEditing] = useState<string | undefined>()
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  if (!shop.user) {
    return (
      <section className="panel" style={{ maxWidth: 520 }}>
        <h2>Your account</h2>
        <p className="muted">Sign in to save addresses, track orders and edit your profile. The cart still works on this browser.</p>
        <div className="actions" style={{ marginTop: 16 }}>
          <Link className="btn primary" to="/sign-in">
            Sign in
          </Link>
          <Link className="btn ghost" to="/orders">
            Orders
          </Link>
        </div>
      </section>
    )
  }

  async function saveProfile(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      await shop.updateProfile({ name, email, phone })
      shop.note('Profile saved.')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not save the profile.')
    } finally {
      setBusy(false)
    }
  }

  async function saveAddress(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      await shop.saveAddress({ ...address, id: editing })
      setAddress({ ...emptyAddress, name: shop.user?.name ?? '', phone: shop.user?.phone ?? '' })
      setEditing(undefined)
      shop.note(editing ? 'Address updated.' : 'Address saved.')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not save the address.')
    } finally {
      setBusy(false)
    }
  }

  function edit(item: Address) {
    setEditing(item.id)
    setAddress({
      label: item.label,
      name: item.name,
      phone: item.phone,
      line: item.line,
      city: item.city,
      pincode: item.pincode,
    })
  }

  return (
    <div className="account-grid">
      <section className="panel">
        <h2>Profile</h2>
        <p className="muted">Signed in as {shop.user.name}.</p>
        <form className="form" onSubmit={(event) => void saveProfile(event)} style={{ marginTop: 12 }}>
          <Field label="Name" value={name} onChange={(event) => setName(event.target.value)} />
          <Field label="Email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
          <Field label="Mobile" value={phone} inputMode="numeric" onChange={(event) => setPhone(event.target.value)} />
          {error ? <p className="error">{error}</p> : null}
          <div className="actions">
            <button className="btn primary" type="submit" disabled={busy}>
              Save profile
            </button>
            <button
              className="btn ghost"
              type="button"
              onClick={() => {
                void shop.logout().then(() => shop.note('Signed out.'))
              }}
            >
              Sign out
            </button>
          </div>
        </form>
        <p style={{ marginTop: 16 }}>
          <Link to="/orders">My orders</Link>
          {' · '}
          <Link to="/help">Help</Link>
          {' · '}
          <Link to="/policies">Policies</Link>
        </p>
      </section>
      <section className="panel">
        <h2>Addresses</h2>
        <div className="form" style={{ margin: '12px 0' }}>
          {shop.addresses.map((item) => (
            <div key={item.id} className={item.isDefault ? 'address on' : 'address'}>
              <strong>{item.label}{item.isDefault ? ' · default' : ''}</strong>
              <span>{item.name} · {item.phone}</span>
              <span>{item.line}, {item.city} {item.pincode}</span>
              <div className="actions">
                <button className="text-btn" type="button" onClick={() => edit(item)}>
                  Edit
                </button>
                {!item.isDefault ? (
                  <button className="text-btn" type="button" onClick={() => void shop.makeDefault(item.id)}>
                    Make default
                  </button>
                ) : null}
                <button className="text-btn" type="button" onClick={() => void shop.deleteAddress(item.id)}>
                  Delete
                </button>
              </div>
            </div>
          ))}
        </div>
        <form className="form two" onSubmit={(event) => void saveAddress(event)}>
          <Field label="Label" value={address.label} onChange={(event) => setAddress({ ...address, label: event.target.value })} />
          <Field label="Name" value={address.name} onChange={(event) => setAddress({ ...address, name: event.target.value })} />
          <Field label="Mobile" value={address.phone} onChange={(event) => setAddress({ ...address, phone: event.target.value })} />
          <Field label="Pincode" value={address.pincode} onChange={(event) => setAddress({ ...address, pincode: event.target.value })} />
          <Field label="Address" value={address.line} onChange={(event) => setAddress({ ...address, line: event.target.value })} />
          <Field label="City" value={address.city} onChange={(event) => setAddress({ ...address, city: event.target.value })} />
          <div className="actions">
            <button className="btn primary" type="submit" disabled={busy}>
              {editing ? 'Update address' : 'Save address'}
            </button>
            {editing ? (
              <button
                className="btn ghost"
                type="button"
                onClick={() => {
                  setEditing(undefined)
                  setAddress(emptyAddress)
                }}
              >
                Cancel
              </button>
            ) : null}
          </div>
        </form>
      </section>
    </div>
  )
}
