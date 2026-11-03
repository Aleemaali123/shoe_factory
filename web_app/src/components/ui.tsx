import { useEffect, type InputHTMLAttributes, type ReactNode } from 'react'
import { Link } from 'react-router-dom'

export function useTitle(title: string) {
  useEffect(() => {
    document.title = title === 'Home' ? 'Shoe Factory' : `${title} · Shoe Factory`
  }, [title])
}

export function Field({
  label,
  ...props
}: { label: string } & InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="field">
      <span>{label}</span>
      <input {...props} />
    </label>
  )
}

export function Empty({
  title,
  body,
  action,
  to,
}: {
  title: string
  body: string
  action?: string
  to?: string
}) {
  return (
    <div className="panel empty">
      <h2>{title}</h2>
      <p className="muted">{body}</p>
      {action && to ? (
        <p style={{ marginTop: 14 }}>
          <Link className="btn primary" to={to}>
            {action}
          </Link>
        </p>
      ) : null}
    </div>
  )
}

export function Money({ label, value, total = false }: { label: string; value: string; total?: boolean }) {
  return (
    <div className={total ? 'money total' : 'money'}>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  )
}

export function Offline({ message }: { message: string }) {
  if (!message) return null
  return <div className="banner">{message}</div>
}

export function Section({
  title,
  extra,
  children,
}: {
  title: string
  extra?: ReactNode
  children: ReactNode
}) {
  return (
    <section>
      <div className="section-head">
        <h2>{title}</h2>
        {extra}
      </div>
      {children}
    </section>
  )
}
