import { useEffect, useState, type FormEvent } from 'react'
import { Field, FormError, PageHeader } from '../components/ui'
import { useAuth, type AdminProfile } from '../data/auth'

export function ProfilePage() {
  const { profile, updateProfile, updateCredentials } = useAuth()
  const [draft, setDraft] = useState<AdminProfile>(profile)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const [username, setUsername] = useState(profile.username)
  const [currentPassword, setCurrentPassword] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [credentialError, setCredentialError] = useState('')
  const [credentialSaved, setCredentialSaved] = useState(false)

  useEffect(() => {
    setDraft(profile)
    setUsername(profile.username)
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
        username: profile.username,
      })
    }
  }

  async function onCredentials(event: FormEvent) {
    event.preventDefault()
    const nextPassword = password.trim()
    if (!currentPassword) {
      setCredentialError('Enter the current password.')
      setCredentialSaved(false)
      return
    }
    if (!username.trim()) {
      setCredentialError('Enter a username.')
      setCredentialSaved(false)
      return
    }
    if (nextPassword || confirmPassword) {
      if (nextPassword.length < 6) {
        setCredentialError('Use a password of at least 6 characters.')
        setCredentialSaved(false)
        return
      }
      if (nextPassword !== confirmPassword) {
        setCredentialError('New passwords do not match.')
        setCredentialSaved(false)
        return
      }
    }
    const message = await updateCredentials({
      currentPassword,
      username: username.trim(),
      password: nextPassword || undefined,
    })
    setCredentialError(message ?? '')
    setCredentialSaved(message == null)
    if (message == null) {
      setCurrentPassword('')
      setPassword('')
      setConfirmPassword('')
    }
  }

  return (
    <>
      <PageHeader title="Profile" lede="Your name, email, and the username and password used to sign in to this desk." />
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
          <Field label="Mobile number" wide>
            <input
              value={draft.phone}
              onChange={(event) => set('phone', event.target.value.replace(/\D/g, '').slice(0, 10))}
              inputMode="numeric"
              autoComplete="tel"
            />
          </Field>
        </div>
        <FormError message={error} />
        {saved ? <p className="saved">Profile saved.</p> : null}
        <div className="actions">
          <button className="btn primary" type="submit">
            Save profile
          </button>
        </div>
      </form>
      <form className="card profile-card" onSubmit={onCredentials}>
        <h2>Sign-in</h2>
        <p className="lede">Change the username or password. The current password is required.</p>
        <div className="fields">
          <Field label="Username" wide>
            <input
              value={username}
              onChange={(event) => {
                setUsername(event.target.value)
                setCredentialSaved(false)
              }}
              autoComplete="username"
            />
          </Field>
          <Field label="Current password" wide>
            <input
              type="password"
              value={currentPassword}
              onChange={(event) => {
                setCurrentPassword(event.target.value)
                setCredentialSaved(false)
              }}
              autoComplete="current-password"
            />
          </Field>
          <Field label="New password" hint="Leave blank to keep the current password." wide>
            <input
              type="password"
              value={password}
              onChange={(event) => {
                setPassword(event.target.value)
                setCredentialSaved(false)
              }}
              autoComplete="new-password"
            />
          </Field>
          <Field label="Confirm new password" wide>
            <input
              type="password"
              value={confirmPassword}
              onChange={(event) => {
                setConfirmPassword(event.target.value)
                setCredentialSaved(false)
              }}
              autoComplete="new-password"
            />
          </Field>
        </div>
        <FormError message={credentialError} />
        {credentialSaved ? <p className="saved">Sign-in details saved. Use them the next time you sign in.</p> : null}
        <div className="actions">
          <button className="btn primary" type="submit">
            Save sign-in
          </button>
        </div>
      </form>
    </>
  )
}
