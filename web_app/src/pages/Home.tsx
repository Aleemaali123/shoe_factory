import { useState } from 'react'
import { Link } from 'react-router-dom'
import { ProductCard, ProductRail } from '../components/ProductCard'
import { Offline, Section, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import { discountPercent, sortProducts } from '../lib/catalog'

export function HomePage() {
  useTitle('Home')
  const shop = useShop()
  const [category, setCategory] = useState('All')
  const featured = sortProducts(shop.products, 'featured')
  const deals = featured.filter((product) => discountPercent(product) > 0).slice(0, 8)
  const fresh = sortProducts(shop.products, 'newest').filter((product) => product.isNew).slice(0, 8)
  const hero = deals[0] ?? featured[0]
  const browsing = category === 'All'
  const listed = featured.filter((product) => browsing || product.category === category)

  return (
    <>
      <Offline message={shop.offline} />
      <section className="hero">
        <div>
          <p className="kicker">Shoe Factory</p>
          <h1>Pairs for the week ahead.</h1>
          <p>Browse the same catalogue as the shop app. Pick a colour and size, then collect from a branch or get it delivered.</p>
          <div className="actions" style={{ marginTop: 18 }}>
            <Link className="btn primary" to="/shop">
              Shop the floor
            </Link>
            <Link className="btn ghost" to={hero ? `/product/${hero.id}` : '/shop'}>
              Featured pair
            </Link>
          </div>
        </div>
        <Link
          className="hero-card"
          to={hero ? `/product/${hero.id}` : '/shop'}
          style={hero ? { backgroundImage: `linear-gradient(transparent, rgba(0,0,0,.45)), url(${hero.imageUrls[0] ?? ''})` } : undefined}
        >
          <strong>{hero ? hero.name : 'New arrivals land here'}</strong>
        </Link>
      </section>
      <div className="trust">
        <div>
          <strong>Store pickup</strong>
          <span>Free from your branch</span>
        </div>
        <div>
          <strong>₹49 delivery</strong>
          <span>Free from ₹4,999</span>
        </div>
        <div>
          <strong>7-day returns</strong>
          <span>Unworn, original box</span>
        </div>
        <div>
          <strong>Coupons</strong>
          <span>{shop.coupons.map((coupon) => coupon.code).join(' · ') || 'Added from admin'}</span>
        </div>
      </div>
      <Section
        title="Shop by category"
        extra={<Link to="/shop">View all</Link>}
      >
        <div className="chips">
          {shop.categories.map((item) => (
            <button key={item} className={item === category ? 'chip on' : 'chip'} type="button" onClick={() => setCategory(item)}>
              {item}
            </button>
          ))}
        </div>
      </Section>
      {browsing && deals.length ? (
        <Section title="Deals this week" extra={<Link to="/shop?sort=priceLow">See deals</Link>}>
          <ProductRail products={deals} />
        </Section>
      ) : null}
      {browsing && fresh.length ? (
        <Section title="New arrivals" extra={<Link to="/shop?sort=newest">See new</Link>}>
          <ProductRail products={fresh} />
        </Section>
      ) : null}
      <Section title={browsing ? 'Trending now' : category} extra={<span className="muted">{listed.length} items</span>}>
        {listed.length ? (
          <div className="grid">
            {listed.slice(0, 8).map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        ) : (
          <p className="muted">Nothing matches that search.</p>
        )}
      </Section>
    </>
  )
}
