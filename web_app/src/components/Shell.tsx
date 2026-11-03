import { useEffect, useState, type FormEvent } from 'react'
import { Link, NavLink, Outlet, useLocation, useNavigate } from 'react-router-dom'
import { useShop } from '../data/shop'

const links = [
  ['/', 'Home'],
  ['/shop', 'Shop'],
  ['/wishlist', 'Wishlist'],
  ['/orders', 'Orders'],
  ['/account', 'Account'],
] as const

export function Shell() {
  const shop = useShop()
  const navigate = useNavigate()
  const location = useLocation()
  const [query, setQuery] = useState('')
  const [menu, setMenu] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const branch = shop.branches.find((item) => item.id === shop.branchId)

  useEffect(() => {
    setMenu(false)
    setSearchOpen(false)
    const params = new URLSearchParams(location.search)
    if (location.pathname === '/shop') setQuery(params.get('q') ?? '')
  }, [location])

  function onSearch(event: FormEvent) {
    event.preventDefault()
    const next = query.trim()
    navigate(next ? `/shop?q=${encodeURIComponent(next)}` : '/shop')
  }

  if (!shop.ready) {
    return (
      <div className="boot">
        <img src="/logo.png" alt="Shoe Factory" />
        <h1>Opening the shop</h1>
        <p>Loading the catalogue, cart and your session.</p>
      </div>
    )
  }

  return (
    <div className="site">
      <a className="skip" href="#content">
        Skip to content
      </a>
      <header className="top">
        <div className="top-row">
          <button className="icon-btn menu-btn" type="button" aria-label="Menu" onClick={() => setMenu((open) => !open)}>
            ☰
          </button>
          <Link className="logo" to="/" aria-label="Shoe Factory home">
            <img src="/logo.png" alt="Shoe Factory" />
          </Link>
          <form className={searchOpen ? 'search open' : 'search'} onSubmit={onSearch} role="search">
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search sneakers, sandals, watches"
              aria-label="Search the shop"
            />
            <button type="submit">Search</button>
          </form>
          <div className="tools">
            <button className="icon-btn menu-btn" type="button" aria-label="Search" onClick={() => setSearchOpen((open) => !open)}>
              ⌕
            </button>
            <Link className="tool" to="/branches" title={branch?.name ?? 'Branch'}>
              ⌖
            </Link>
            <Link className="tool" to="/notices" aria-label="Notifications">
              ✉{shop.unread > 0 ? <span className="dot">{shop.unread}</span> : null}
            </Link>
            <Link className="tool" to="/cart" aria-label="Cart">
              ▢{shop.cartCount > 0 ? <span className="count">{shop.cartCount}</span> : null}
            </Link>
          </div>
        </div>
        <nav className={menu ? 'nav-row open' : 'nav-row'} aria-label="Shop">
          {links.map(([to, label]) => (
            <NavLink key={to} to={to} end={to === '/'}>
              {label}
              {to === '/wishlist' && shop.wishlist.length ? ` (${shop.wishlist.length})` : ''}
            </NavLink>
          ))}
          <NavLink to="/help">Help</NavLink>
        </nav>
      </header>
      <main className="page" id="content">
        <Outlet />
      </main>
      <footer className="footer">
        <div className="footer-inner">
          <div>
            <strong>Shoe Factory</strong>
            <p>Pairs, pickup and delivery from the same shop the app uses.</p>
          </div>
          <div>
            <Link to="/policies">Policies</Link>
            <Link to="/help">Help</Link>
            <Link to="/branches">Branches</Link>
            <Link to="/account">Account</Link>
          </div>
        </div>
      </footer>
      {shop.flash ? (
        <div className="toast" role="status">
          <span>{shop.flash}</span>
          <button type="button" onClick={shop.clearFlash}>
            Dismiss
          </button>
        </div>
      ) : null}
    </div>
  )
}
