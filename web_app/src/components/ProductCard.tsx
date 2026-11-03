import { Link } from 'react-router-dom'
import { useShop } from '../data/shop'
import { coverImage, discountPercent } from '../lib/catalog'
import { formatRupees } from '../lib/format'
import type { Product } from '../types'

export function ProductCard({ product }: { product: Product }) {
  const shop = useShop()
  const saved = shop.wishlist.includes(product.id)
  const off = discountPercent(product)
  const image = coverImage(product)

  return (
    <article className="card">
      <Link to={`/product/${product.id}`} className="media" style={image ? { backgroundImage: `url(${image})` } : undefined}>
        {off > 0 ? <span className="tag sale">{off}% off</span> : product.badge ? <span className="tag">{product.badge}</span> : null}
        {product.stock <= 0 ? <span className="tag">Out of stock</span> : null}
      </Link>
      <button
        className={saved ? 'wish on' : 'wish'}
        type="button"
        aria-label={saved ? 'Remove from wishlist' : 'Save to wishlist'}
        onClick={() => {
          void shop.toggleWish(product.id).then(
            () => shop.note(saved ? 'Removed from wishlist.' : 'Saved to wishlist.'),
            (error: unknown) => shop.note(error instanceof Error ? error.message : 'Could not update the wishlist.'),
          )
        }}
      >
        {saved ? '♥' : '♡'}
      </button>
      <div className="card-body">
        <p className="muted">{product.category}</p>
        <h3>
          <Link to={`/product/${product.id}`}>{product.name}</Link>
        </h3>
        <p className="stars">
          ★ {product.rating.toFixed(1)} <span className="muted">({product.reviewCount})</span>
        </p>
        <p className="price">
          {formatRupees(product.price)}
          {off > 0 ? <s>{formatRupees(product.oldPrice)}</s> : null}
        </p>
      </div>
    </article>
  )
}

export function ProductRail({ products }: { products: Product[] }) {
  return (
    <div className="rail">
      {products.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}
