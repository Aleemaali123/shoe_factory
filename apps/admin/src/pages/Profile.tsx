import { useEffect, useState, type FormEvent } from 'react'
import { Field, FormError, PageHeader } from '../components/ui'
import { useAuth, type AdminProfile } from '../data/auth'

export function ProfilePage() {
  const { profile, updateProfile } = useAuth()
  const [draft, setDraft] = useState<AdminProfile>(profile)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    setDraft(profile)
  }, [profile])

  function set<K extends keyof AdminProfile>(key: K, value: AdminProfile[K]) {
    setDraft((current) => ({ ...current, [key]: value }))
    setSaved(false)
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    const message = await updateProfile(draft)
    setError(message ?? '')
    setSaved(message == null)
    if (message == null) {
      setDraft({
        name: draft.name.trim(),
        email: draft.email.trim(),
        phone: draft.phone.replace(/\D/g, ''),
      })
    }
  }

  return (
    <>
      <PageHeader title="Profile" lede="Your name, email, and the mobile number used to sign in to this desk." />
      <form className="card profile-card" onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Name" wide>
            <input
              value={draft.name}
              onChange={(event) => set('name', event.target.value)}
              autoComplete="name"
            />
          </Field>
          <Field label="Email" wide>
            <input
              value={draft.email}
              onChange={(event) => set('email', event.target.value)}
              autoComplete="email"
              inputMode="email"
            />
          </Field>
          <Field label="Mobile number" hint="This is the number that receives the sign-in code." wide>
            <input
              value={draft.phone}
              onChange={(event) => set('phone', event.target.value.replace(/\D/g, '').slice(0, 10))}
              inputMode="numeric"
              autoComplete="tel"
            />
          </Field>
        </div>
        <FormError message={error} />
        {saved ? <p className="saved">Profile saved. Use this mobile number the next time you sign in.</p> : null}
        <div className="actions">
          <button className="btn primary" type="submit">
            Save profile
          </button>
        </div>
      </form>
    </>
  )
}
