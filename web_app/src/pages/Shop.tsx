import { useSearchParams } from 'react-router-dom'
import { ProductCard } from '../components/ProductCard'
import { Offline, useTitle } from '../components/ui'
import { useShop } from '../data/shop'
import { filterProducts, sortProducts, sorts } from '../lib/catalog'
import type { SortKey } from '../types'

export function ShopPage() {
  useTitle('Shop')
  const shop = useShop()
  const [params, setParams] = useSearchParams()
  const query = params.get('q') ?? ''
  const category = params.get('category') ?? 'All'
  const sort = (sorts.some((item) => item.id === params.get('sort')) ? params.get('sort') : 'featured') as SortKey
  const products = sortProducts(filterProducts(shop.products, query, category), sort)

  function update(next: { q?: string; category?: string; sort?: SortKey }) {
    const merged = { q: query, category, sort, ...next }
    const search = new URLSearchParams()
    if (merged.q) search.set('q', merged.q)
    if (merged.category && merged.category !== 'All') search.set('category', merged.category)
    if (merged.sort !== 'featured') search.set('sort', merged.sort)
    setParams(search, { replace: true })
  }

  return (
    <>
      <Offline message={shop.offline} />
      <div className="section-head">
        <div>
          <h2>{query ? `Results for “${query}”` : category === 'All' ? 'Shop' : category}</h2>
          <p className="muted">{products.length} items</p>
        </div>
        <label className="field" style={{ minWidth: 220 }}>
          <span>Sort</span>
          <select value={sort} onChange={(event) => update({ sort: event.target.value as SortKey })}>
            {sorts.map((item) => (
              <option key={item.id} value={item.id}>
                {item.label}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="chips" style={{ marginBottom: 16 }}>
        {shop.categories.map((item) => (
          <button key={item} type="button" className={item === category ? 'chip on' : 'chip'} onClick={() => update({ category: item })}>
            {item}
          </button>
        ))}
      </div>
      {products.length ? (
        <div className="grid">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      ) : (
        <div className="panel empty">
          <h2>Nothing matches that search.</h2>
          <p className="muted">Try another word, or clear the category filter.</p>
        </div>
      )}
    </>
  )
}
