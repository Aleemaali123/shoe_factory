import { useState, type FormEvent } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { Field, useTitle } from '../components/ui'
import { useShop } from '../data/shop'

export function SignInPage() {
  useTitle('Sign in')
  const shop = useShop()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: string } | null)?.from || '/account'
  const [mode, setMode] = useState<'phone' | 'email'>('phone')
  const [phone, setPhone] = useState('9876543210')
  const [code, setCode] = useState('')
  const [issued, setIssued] = useState('')
  const [needsProfile, setNeedsProfile] = useState(false)
  const [name, setName] = useState('')
  const [email, setEmail] = useState('shopper@shoefactory.shop')
  const [password, setPassword] = useState('')
  const [resetting, setResetting] = useState(false)
  const [resetCode, setResetCode] = useState('')
  const [nextPassword, setNextPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  if (shop.user) return <Navigate to={from} replace />

  async function sendCode(event?: FormEvent) {
    event?.preventDefault()
    setBusy(true)
    setError('')
    try {
      const result = await shop.requestOtp(phone)
      setIssued(result.code)
      setNeedsProfile(!result.registered)
      setCode('')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not send a code.')
    } finally {
      setBusy(false)
    }
  }

  async function verify(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      if (needsProfile) {
        await shop.registerWithOtp({ name, email, phone, code })
        navigate(from)
        return
      }
      const result = await shop.verifyOtp(phone, code)
      if (result.needsProfile) {
        setNeedsProfile(true)
        return
      }
      navigate(from)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'That code could not be verified.')
    } finally {
      setBusy(false)
    }
  }

  async function emailSignIn(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      await shop.login(email, password)
      navigate(from)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not sign in.')
    } finally {
      setBusy(false)
    }
  }

  async function sendReset(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      const result = await shop.requestPasswordReset(email)
      setResetCode(result.code)
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not start a reset.')
    } finally {
      setBusy(false)
    }
  }

  async function finishReset(event: FormEvent) {
    event.preventDefault()
    setBusy(true)
    setError('')
    try {
      await shop.resetPassword({
        email,
        code: resetCode,
        password: nextPassword,
        confirmPassword: nextPassword,
      })
      setResetting(false)
      setPassword(nextPassword)
      setError('')
      shop.note('Password updated. Sign in with the new password.')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not reset the password.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <section className="layout">
      <div className="panel">
        <p className="kicker" style={{ color: 'var(--deep)' }}>Shoe Factory</p>
        <h2>Sign in</h2>
        <p className="muted">Use the shop mobile number and the 6-digit code, or the shop email. The demo code is shown here because no SMS is sent.</p>
        <div className="chips" style={{ margin: '14px 0' }}>
          <button type="button" className={mode === 'phone' ? 'chip on' : 'chip'} onClick={() => setMode('phone')}>
            Mobile
          </button>
          <button type="button" className={mode === 'email' ? 'chip on' : 'chip'} onClick={() => setMode('email')}>
            Email
          </button>
        </div>
        {mode === 'phone' ? (
          <form className="form" onSubmit={(event) => void (issued ? verify(event) : sendCode(event))}>
            <Field label="Mobile number" value={phone} inputMode="numeric" onChange={(event) => setPhone(event.target.value)} />
            {issued ? (
              <>
                <p className="ok">Demo code {issued}. It expires in 5 minutes.</p>
                <Field label="6-digit code" value={code} inputMode="numeric" onChange={(event) => setCode(event.target.value)} />
                {needsProfile ? (
                  <>
                    <Field label="Name" value={name} onChange={(event) => setName(event.target.value)} />
                    <Field label="Email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
                  </>
                ) : null}
              </>
            ) : null}
            {error ? <p className="error">{error}</p> : null}
            <button className="btn primary" type="submit" disabled={busy}>
              {issued ? 'Verify and continue' : 'Send code'}
            </button>
            {issued ? (
              <button className="text-btn" type="button" onClick={() => void sendCode()}>
                Resend code
              </button>
            ) : null}
          </form>
        ) : resetting ? (
          <form className="form" onSubmit={(event) => void (resetCode ? finishReset(event) : sendReset(event))}>
            <Field label="Email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
            {resetCode ? (
              <>
                <p className="ok">Reset code {resetCode}.</p>
                <Field label="New password" type="password" value={nextPassword} onChange={(event) => setNextPassword(event.target.value)} />
              </>
            ) : null}
            {error ? <p className="error">{error}</p> : null}
            <button className="btn primary" type="submit" disabled={busy}>
              {resetCode ? 'Update password' : 'Send reset code'}
            </button>
          </form>
        ) : (
          <form className="form" onSubmit={(event) => void emailSignIn(event)}>
            <Field label="Email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} />
            <Field label="Password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} />
            {error ? <p className="error">{error}</p> : null}
            <button className="btn primary" type="submit" disabled={busy}>
              Sign in
            </button>
            <button className="text-btn" type="button" onClick={() => setResetting(true)}>
              Forgot password
            </button>
            <p className="muted">Demo email shopper@shoefactory.shop, password trend.</p>
          </form>
        )}
      </div>
      <aside className="help-hero">
        <h2>Same shop, in the browser.</h2>
        <p>Cart, coupons, branches and orders stay on the shop API, so the Flutter app and this site read the same floor.</p>
      </aside>
    </section>
  )
}
