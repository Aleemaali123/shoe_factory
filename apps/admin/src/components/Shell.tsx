import { useEffect, useState } from 'react'
import { NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../data/auth'
import { useCatalog } from '../data/catalog'
import { useStore } from '../data/store'
import { isOpen } from '../lib/format'
import { stockState } from '../lib/stock'

const links = [
  { to: '/', label: 'Overview', end: true },
  { to: '/products', label: 'Products', end: false },
  { to: '/orders', label: 'Orders', end: false },
  { to: '/customers', label: 'Customers', end: false },
  { to: '/branches', label: 'Branches', end: false },
  { to: '/coupons', label: 'Coupons', end: false },
  { to: '/notices', label: 'Notices', end: false },
  { to: '/profile', label: 'Profile', end: false },
]

export function Shell() {
  const { data, flash, dismissFlash, resetDemo } = useStore()
  const { products, flash: productFlash, dismissFlash: dismissProductFlash } = useCatalog()
  const { name, phone, signOut } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [open, setOpen] = useState(false)
  const openOrders = data.orders.filter((order) => isOpen(order.status)).length
  const stockAlerts = products.filter((product) => {
    const state = stockState(product)
    return state === 'low' || state === 'out'
  }).length

  useEffect(() => {
    setOpen(false)
  }, [location.pathname])

  useEffect(() => {
    const current = links.find((link) => (link.end ? location.pathname === '/' : location.pathname.startsWith(link.to)))
    document.title = current ? `${current.label} · Shoe Factory` : 'Shoe Factory Admin'
  }, [location.pathname])

  return (
    <div className="app-shell">
      {open ? <button className="scrim nav-scrim" aria-label="Close menu" onClick={() => setOpen(false)} /> : null}
      <aside className={open ? 'sidebar open' : 'sidebar'}>
        <div className="brand">
          <img src="/logo.png" alt="Shoe Factory" />
          <span className="brand-kicker">Admin</span>
        </div>
        <nav className="nav">
          {links.map((link) => (
            <NavLink key={link.to} to={link.to} end={link.end} className={({ isActive }) => (isActive ? 'active' : undefined)}>
              {link.label}
              {link.to === '/orders' && openOrders > 0 ? <em className="badge">{openOrders}</em> : null}
              {link.to === '/products' && stockAlerts > 0 ? <em className="badge warn">{stockAlerts}</em> : null}
            </NavLink>
          ))}
        </nav>
        <div className="side-foot">
          <p>
            Signed in as
            <NavLink to="/profile" className="who-link">
              <strong>{name}</strong>
              {phone ? <span>+91 {phone}</span> : null}
            </NavLink>
          </p>
          <button type="button" className="btn ghost" onClick={resetDemo}>
            Restore demo data
          </button>
          <button
            type="button"
            className="btn ghost"
            onClick={() => {
              signOut()
              navigate('/login')
            }}
          >
            Sign out
          </button>
        </div>
      </aside>
      <div className="main">
        <div className="topbar">
          <button type="button" className="menu-btn" onClick={() => setOpen(true)}>
            Menu
          </button>
          <span className="who">{name}</span>
        </div>
        {flash || productFlash ? (
          <div className="flash" role="status">
            <span>{productFlash || flash}</span>
            <button type="button" onClick={productFlash ? dismissProductFlash : dismissFlash}>
              Dismiss
            </button>
          </div>
        ) : null}
        <div className="content">
          <Outlet />
        </div>
      </div>
    </div>
  )
}
