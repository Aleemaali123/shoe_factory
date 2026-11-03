import { ProductCard } from '../components/ProductCard'
import { Empty, useTitle } from '../components/ui'
import { useShop } from '../data/shop'

export function WishlistPage() {
  useTitle('Wishlist')
  const shop = useShop()
  const products = shop.wishlist
    .map((id) => shop.products.find((product) => product.id === id))
    .filter((product) => product != null)

  if (!products.length) {
    return <Empty title="Nothing saved yet" body="Tap the heart on a pair to keep it here." action="Browse the shop" to="/shop" />
  }

  return (
    <section>
      <div className="section-head">
        <h2>Wishlist</h2>
        <span className="muted">{products.length} saved</span>
      </div>
      <div className="grid">
        {products.map((product) => (
          <ProductCard key={product.id} product={product} />
        ))}
      </div>
    </section>
  )
}
