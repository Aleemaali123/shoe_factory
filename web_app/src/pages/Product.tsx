import { useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Empty, useTitle } from '../components/ui'
import { getProduct } from '../data/api'
import { useShop } from '../data/shop'
import { discountPercent, galleryFor, shoeColor, sizeGuide, sizeHeading, sizeOption } from '../lib/catalog'
import { formatRupees } from '../lib/format'
import type { Product } from '../types'

export function ProductPage() {
  const { id = '' } = useParams()
  const shop = useShop()
  const navigate = useNavigate()
  const known = shop.products.find((item) => item.id === id) ?? null
  const [extra, setExtra] = useState<Product | null>(null)
  const [missing, setMissing] = useState(false)
  const product = known ?? (extra?.id === id ? extra : null)
  const [color, setColor] = useState('')
  const [size, setSize] = useState<number | null>(null)
  const [qty, setQty] = useState(1)
  const [shot, setShot] = useState(0)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  useTitle(product?.name ?? 'Pair')

  useEffect(() => {
    setExtra(null)
    setMissing(false)
    setError('')
  }, [id])

  const prepared = useRef('')
  useEffect(() => {
    if (!product || prepared.current === product.id) return
    prepared.current = product.id
    setColor(product.colors[0] ?? '')
    setSize(product.sizes[0] ?? null)
    setQty(1)
    setShot(0)
  }, [product])

  useEffect(() => {
    if (known || !shop.ready) return
    let cancelled = false
    getProduct(id).then(
      (found) => {
        if (!cancelled) setExtra(found)
      },
      () => {
        if (!cancelled) setMissing(true)
      },
    )
    return () => {
      cancelled = true
    }
  }, [id, known, shop.ready])

  if (missing) return <Empty title="That pair is gone" body="It may have been hidden from the shop." action="Back to the shop" to="/shop" />
  if (!product) return <p className="muted">Loading this pair…</p>

  const gallery = galleryFor(product, color)
  const image = gallery[shot] || gallery[0] || ''
  const off = discountPercent(product)
  const cap = Math.min(5, product.stock)
  const saved = shop.wishlist.includes(product.id)

  async function add(thenCheckout: boolean) {
    if (!product || size == null) {
      setError('Choose a size first.')
      return
    }
    setBusy(true)
    setError('')
    try {
      const result = await shop.addToCart({ productId: product.id, color, size, quantity: qty })
      shop.note(result.message)
      if (result.added && thenCheckout) navigate('/checkout')
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : 'Could not add this pair.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <article className="product">
      <div className="gallery">
        <div className="hero-shot">{image ? <img src={image} alt={product.name} /> : null}</div>
        {gallery.length > 1 ? (
          <div className="thumbs">
            {gallery.map((url, index) => (
              <button key={url} type="button" className={index === shot ? 'on' : ''} onClick={() => setShot(index)}>
                <img src={url} alt="" />
              </button>
            ))}
          </div>
        ) : null}
      </div>
      <div>
        <p className="muted">{product.category}</p>
        <h1>{product.name}</h1>
        <p className="stars">★ {product.rating.toFixed(1)} · {product.reviewCount} reviews</p>
        <p className="price" style={{ fontSize: 28 }}>
          {formatRupees(product.price)}
          {off > 0 ? <s>{formatRupees(product.oldPrice)}</s> : null}
          {off > 0 ? <span className="pill good">{off}% off</span> : null}
        </p>
        <p style={{ marginTop: 12 }}>{product.description}</p>
        {product.stock <= 0 ? <p className="error">Out of stock</p> : product.stock <= 5 ? <p className="ok">Only {product.stock} left</p> : null}
        {product.colors.length ? (
          <div className="choice">
            <strong>Colour · {color}</strong>
            <div className="swatches">
              {product.colors.map((item) => (
                <button
                  key={item}
                  type="button"
                  className={item === color ? 'swatch on' : 'swatch'}
                  aria-label={item}
                  title={item}
                  style={{ background: shoeColor(item) }}
                  onClick={() => {
                    setColor(item)
                    setShot(0)
                  }}
                />
              ))}
            </div>
          </div>
        ) : null}
        {product.sizes.length ? (
          <div className="choice">
            <strong>{sizeHeading(product.category)}</strong>
            <div className="sizes">
              {product.sizes.map((item) => (
                <button key={item} type="button" className={item === size ? 'size on' : 'size'} onClick={() => setSize(item)}>
                  {sizeOption(product.category, item)}
                </button>
              ))}
            </div>
            <p className="muted">{sizeGuide(product.category)}</p>
          </div>
        ) : null}
        <div className="choice">
          <strong>Quantity</strong>
          <div className="stepper">
            <button type="button" onClick={() => setQty((value) => Math.max(1, value - 1))} aria-label="Decrease quantity">
              −
            </button>
            <span>{qty}</span>
            <button type="button" onClick={() => setQty((value) => Math.min(cap || 1, value + 1))} aria-label="Increase quantity">
              +
            </button>
          </div>
        </div>
        {error ? <p className="error">{error}</p> : null}
        <div className="actions" style={{ marginTop: 18 }}>
          <button className="btn primary" type="button" disabled={busy || product.stock <= 0} onClick={() => void add(false)}>
            Add to cart
          </button>
          <button className="btn line" type="button" disabled={busy || product.stock <= 0} onClick={() => void add(true)}>
            Buy now
          </button>
          <button
            className="btn ghost"
            type="button"
            onClick={() => {
              void shop.toggleWish(product.id).then(
                () => shop.note(saved ? 'Removed from wishlist.' : 'Saved to wishlist.'),
                (caught: unknown) => shop.note(caught instanceof Error ? caught.message : 'Could not update the wishlist.'),
              )
            }}
          >
            {saved ? 'Saved' : 'Save'}
          </button>
        </div>
        {product.reviews.length ? (
          <section style={{ marginTop: 28 }}>
            <h2>Reviews</h2>
            {product.reviews.map((review) => (
              <div key={`${review.author}-${review.comment}`} className="panel" style={{ marginTop: 10 }}>
                <strong>{review.author}</strong>
                <p className="stars">★ {review.rating.toFixed(1)}</p>
                <p>{review.comment}</p>
              </div>
            ))}
          </section>
        ) : null}
        <p style={{ marginTop: 18 }}>
          <Link to="/shop">Back to the shop</Link>
        </p>
      </div>
    </article>
  )
}
