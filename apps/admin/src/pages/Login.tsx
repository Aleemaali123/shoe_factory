import { useEffect, useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../data/auth'

export function LoginPage() {
  const { name, profile, signIn } = useAuth()
  const [username, setUsername] = useState(profile.username)
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    document.title = 'Sign in · ShoeFactory Admin'
  }, [])

  useEffect(() => {
    setUsername((current) => current || profile.username)
  }, [profile.username])

  if (name) return <Navigate to="/" replace />

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    const message = await signIn(username, password)
    setError(message ?? '')
    setBusy(false)
  }

  return (
    <div className="login">
      <aside className="login-aside">
        <div className="brand light">
          <img src="/logo.png" alt="Shoe Factory" />
          <span className="brand-kicker">Admin</span>
        </div>
        <div>
          <h1>The floor, the stock and the orders.</h1>
          <p>Same catalogue the shop app sells, run from this desk.</p>
        </div>
        <ul>
          <li>Trivandrum Central</li>
          <li>Kochi Marine Drive</li>
          <li>Calicut Main</li>
        </ul>
      </aside>
      <section className="login-panel">
        <form className="login-card" onSubmit={onSubmit}>
          <h2>Sign in</h2>
          <p className="lede">Use the admin username and password stored on the shop API.</p>
          <label className="field">
            <span>Username</span>
            <input
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              autoComplete="username"
              placeholder="Username"
            />
          </label>
          <label className="field">
            <span>Password</span>
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="current-password"
              placeholder="Password"
            />
          </label>
          {error ? <p className="error">{error}</p> : null}
          <button className="btn primary" type="submit" disabled={busy}>
            {busy ? 'Signing in' : 'Enter the desk'}
          </button>
        </form>
      </section>
    </div>
  )
}
