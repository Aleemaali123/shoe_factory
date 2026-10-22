import { useEffect, useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { useAuth } from '../data/auth'

export function LoginPage() {
  const { name, profile, requestOtp, verifyOtp } = useAuth()
  const [phone, setPhone] = useState(profile.phone)
  const [code, setCode] = useState('')
  const [issued, setIssued] = useState('')
  const [error, setError] = useState('')

  useEffect(() => {
    document.title = 'Sign in · Shoe Factory'
  }, [])

  useEffect(() => {
    if (!issued) setPhone(profile.phone)
  }, [profile.phone, issued])

  if (name) return <Navigate to="/" replace />

  async function sendCode(event: FormEvent) {
    event.preventDefault()
    const result = await requestOtp(phone)
    if (!result.ok || !result.code) {
      setIssued('')
      setError(result.error ?? 'Could not send a code.')
      return
    }
    setIssued(result.code)
    setCode('')
    setError('')
  }

  async function confirmCode(event: FormEvent) {
    event.preventDefault()
    const message = await verifyOtp(phone, code)
    setError(message ?? '')
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
        <form className="login-card" onSubmit={issued ? confirmCode : sendCode}>
          <h2>Sign in</h2>
          <p className="lede">Use the admin mobile number stored on the shop API.</p>
          <label className="field">
            <span>Mobile number</span>
            <input
              value={phone}
              onChange={(event) => setPhone(event.target.value.replace(/\D/g, '').slice(0, 10))}
              inputMode="numeric"
              autoComplete="tel"
              disabled={Boolean(issued)}
              placeholder="10-digit mobile"
            />
          </label>
          {issued ? (
            <>
              <label className="field">
                <span>6-digit code</span>
                <input
                  className="otp-input"
                  value={code}
                  onChange={(event) => setCode(event.target.value.replace(/\D/g, '').slice(0, 6))}
                  inputMode="numeric"
                  autoComplete="one-time-code"
                  placeholder="••••••"
                />
              </label>
              <p className="demo-code">
                Demo code <strong>{issued}</strong>
                <span>Expires in 5 minutes. No SMS is sent.</span>
              </p>
            </>
          ) : null}
          {error ? <p className="error">{error}</p> : null}
          <button className="btn primary" type="submit">
            {issued ? 'Enter the desk' : 'Send code'}
          </button>
          {issued ? (
            <button
              className="linkish"
              type="button"
              onClick={() => {
                setIssued('')
                setCode('')
                setError('')
              }}
            >
              Use a different number
            </button>
          ) : null}
          <p className="hint">Admin mobile {profile.phone}</p>
        </form>
      </section>
    </div>
  )
}
