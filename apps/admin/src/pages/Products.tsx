import { useMemo, useState, type FormEvent } from 'react'
import { useCatalog } from '../data/catalog'
import { useStore } from '../data/store'
import { formatRupees } from '../lib/format'
import { stockLabel, stockState, stockTone } from '../lib/stock'
import { categories, photoPositions, productPhotos, type Product, type StockFilter } from '../types'
import { Field, FormError, Modal, PageHeader } from '../components/ui'

const filters: { id: StockFilter; label: string; hint: string }[] = [
  { id: 'all', label: 'All products', hint: 'Every pair in the catalogue' },
  { id: 'in', label: 'In stock', hint: 'More than 5 on hand' },
  { id: 'low', label: 'Low stock', hint: '1 to 5 left' },
  { id: 'out', label: 'Out of stock', hint: 'Nothing left to sell' },
  { id: 'hidden', label: 'Hidden', hint: 'Not listed in the shop' },
]

const blank = (): Product => ({
  id: `sf${Date.now().toString().slice(-6)}`,
  name: '',
  category: 'Sneakers',
  price: 0,
  oldPrice: 0,
  rating: 4.5,
  reviewCount: 0,
  imageUrl: '',
  images: [],
  description: '',
  colors: ['Black', 'White'],
  sizes: [6, 7, 8, 9, 10, 11],
  stock: 0,
  isNew: true,
  listed: true,
})

export function ProductsPage() {
  const { data } = useStore()
  const { products, loading, error, saveProduct, deleteProduct, adjustStock } = useCatalog()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('All')
  const [filter, setFilter] = useState<StockFilter>('all')
  const [editing, setEditing] = useState<Product | null>(null)

  const sold = useMemo(() => {
    const totals = new Map<string, number>()
    for (const order of data.orders) {
      if (order.status === 'cancelled') continue
      for (const line of order.lines) {
        totals.set(line.productId, (totals.get(line.productId) ?? 0) + line.quantity)
      }
    }
    return totals
  }, [data.orders])

  const counts = useMemo(() => {
    const tally = { all: products.length, onHand: 0, in: 0, low: 0, out: 0, hidden: 0 }
    for (const product of products) {
      tally.onHand += product.stock
      tally[stockState(product)] += 1
    }
    return tally
  }, [products])

  const rows = useMemo(() => {
    const needle = query.trim().toLowerCase()
    return products.filter((product) => {
      const matchesQuery =
        !needle ||
        product.name.toLowerCase().includes(needle) ||
        product.id.toLowerCase().includes(needle) ||
        product.category.toLowerCase().includes(needle)
      const matchesCategory = category === 'All' || product.category === category
      const matchesStock = filter === 'all' || stockState(product) === filter
      return matchesQuery && matchesCategory && matchesStock
    })
  }, [products, query, category, filter])

  return (
    <>
      <PageHeader
        title="Products"
        lede="Products saved here are stored on the shop API and listed in the app."
      >
        <button type="button" className="btn primary" onClick={() => setEditing(blank())}>
          Add product
        </button>
      </PageHeader>
      <section className="stats inventory">
        {filters.map((item) => (
          <button
            key={item.id}
            type="button"
            className={filter === item.id ? 'stat on' : 'stat'}
            onClick={() => setFilter(item.id)}
          >
            <span>{item.label}</span>
            <strong>{counts[item.id]}</strong>
            <em>{item.hint}</em>
          </button>
        ))}
        <article className="stat">
          <span>Units on hand</span>
          <strong>{counts.onHand}</strong>
          <em>Shoes left across every pair</em>
        </article>
      </section>
      {error ? <p className="banner">{error}</p> : null}
      {loading ? <p className="empty">Loading products…</p> : null}
      <div className="filters">
        <input
          className="search"
          placeholder="Search name, id or category"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <select value={category} onChange={(event) => setCategory(event.target.value)} aria-label="Category">
          <option>All</option>
          {categories.map((item) => (
            <option key={item}>{item}</option>
          ))}
        </select>
        <p className="count-line">
          Showing {rows.length} of {counts.all}
        </p>
      </div>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Product</th>
              <th>Category</th>
              <th className="num">Price</th>
              <th>Stock</th>
              <th>Status</th>
              <th className="num">Sold</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {rows.map((product) => {
              const state = stockState(product)
              return (
                <tr key={product.id}>
                  <td>
                    <div className="pair">
                      <img className="thumb" src={product.imageUrl} alt="" />
                      <div>
                        <strong>{product.name}</strong>
                        <small>
                          {productPhotos(product)
                            .map((image) => image.position)
                            .join(' · ') || 'No photos'}
                        </small>
                        <small>
                          {product.id}
                          {product.badge ? ` · ${product.badge}` : ''}
                          {product.isNew ? ' · New' : ''}
                        </small>
                        <small>
                          {product.colors.join(', ')} · UK {product.sizes.join(', ')}
                        </small>
                      </div>
                    </div>
                  </td>
                  <td>{product.category}</td>
                  <td className="num">
                    {formatRupees(product.price)}
                    {product.oldPrice > product.price ? <small>{formatRupees(product.oldPrice)}</small> : null}
                  </td>
                  <td>
                    <div className="stock">
                      <button type="button" onClick={() => void adjustStock(product.id, -1)} aria-label={`Decrease ${product.name}`}>
                        −
                      </button>
                      <span className={state === 'out' || state === 'low' ? 'danger' : ''}>{product.stock}</span>
                      <button type="button" onClick={() => void adjustStock(product.id, 1)} aria-label={`Increase ${product.name}`}>
                        +
                      </button>
                    </div>
                  </td>
                  <td>
                    <span className={`pill tone-${stockTone(state)}`}>{stockLabel(state)}</span>
                  </td>
                  <td className="num">{sold.get(product.id) ?? 0}</td>
                  <td className="row-actions">
                    <button type="button" className="btn small ghost" onClick={() => setEditing(product)}>
                      Edit
                    </button>
                    <button
                      type="button"
                      className="btn small danger"
                      onClick={() => {
                        if (window.confirm(`Remove ${product.name}?`)) void deleteProduct(product.id)
                      }}
                    >
                      Remove
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
        {!loading && rows.length === 0 ? <p className="empty">{emptyCopy(filter, query)}</p> : null}
      </div>
      {editing ? (
        <ProductForm
          product={editing}
          onClose={() => setEditing(null)}
          onSave={async (product, creating) => {
            try {
              await saveProduct(product, creating)
              setEditing(null)
              setFilter('all')
              setQuery('')
              return ''
            } catch (err) {
              return err instanceof Error ? err.message : 'Could not save that product.'
            }
          }}
        />
      ) : null}
    </>
  )
}

function readImageFile(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('read'))
    reader.onload = () => {
      const image = new Image()
      image.onload = () => {
        const max = 900
        const scale = Math.min(1, max / Math.max(image.width, image.height))
        const canvas = document.createElement('canvas')
        canvas.width = Math.max(1, Math.round(image.width * scale))
        canvas.height = Math.max(1, Math.round(image.height * scale))
        const context = canvas.getContext('2d')
        if (!context) {
          resolve(String(reader.result))
          return
        }
        context.fillStyle = '#ffffff'
        context.fillRect(0, 0, canvas.width, canvas.height)
        context.drawImage(image, 0, 0, canvas.width, canvas.height)
        resolve(canvas.toDataURL('image/jpeg', 0.82))
      }
      image.onerror = () => reject(new Error('image'))
      image.src = String(reader.result)
    }
    reader.readAsDataURL(file)
  })
}

type PhotoDraft = { url: string; position: string; urlText: string }

function photosFrom(product: Product): PhotoDraft[] {
  const images = productPhotos(product)
  if (images.length === 0) return [{ url: '', position: 'Front', urlText: '' }]
  return images.map((image) => ({
    url: image.url,
    position: image.position || 'Front',
    urlText: image.url.startsWith('data:') ? '' : image.url,
  }))
}

function emptyCopy(filter: StockFilter, query: string) {
  if (query.trim()) return 'No products match that search.'
  if (filter === 'out') return 'No products are out of stock.'
  if (filter === 'low') return 'No products are low on stock.'
  if (filter === 'hidden') return 'No products are hidden.'
  if (filter === 'in') return 'No products are in stock.'
  return 'No products yet. Add one to start the catalogue.'
}

function ProductForm({
  product,
  onClose,
  onSave,
}: {
  product: Product
  onClose: () => void
  onSave: (product: Product, creating: boolean) => Promise<string>
}) {
  const [draft, setDraft] = useState(product)
  const [colors, setColors] = useState(product.colors.join(', '))
  const [sizes, setSizes] = useState(product.sizes.join(', '))
  const [photos, setPhotos] = useState(() => photosFrom(product))
  const [error, setError] = useState('')
  const [saving, setSaving] = useState(false)
  const isNew = !product.name

  function update<K extends keyof Product>(key: K, value: Product[K]) {
    setDraft((current) => ({ ...current, [key]: value }))
  }

  async function onSubmit(event: FormEvent) {
    event.preventDefault()
    if (saving) return
    const price = Number(draft.price)
    const oldPrice = Number(draft.oldPrice) || price
    const stock = Number(draft.stock)
    const parsedSizes = sizes
      .split(',')
      .map((item) => Number(item.trim()))
      .filter((item) => Number.isInteger(item) && item > 0)
    const parsedColors = colors
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean)
    const images = photos
      .filter((photo) => photo.url.trim())
      .map((photo) => ({ url: photo.url.trim(), position: photo.position || 'Front' }))
    if (!draft.name.trim()) return setError('Enter a product name.')
    if (images.length === 0) return setError('Add at least one photo, by upload or URL.')
    if (!Number.isFinite(price) || price <= 0) return setError('Enter a valid price.')
    if (!Number.isInteger(stock) || stock < 0) return setError('Stock has to be a whole number. Use 0 for out of stock.')
    if (parsedColors.length === 0) return setError('Add at least one colour.')
    if (parsedSizes.length === 0) return setError('Add at least one UK size.')
    setSaving(true)
    const message = await onSave(
      {
        ...draft,
        name: draft.name.trim(),
        price,
        oldPrice: oldPrice < price ? price : oldPrice,
        stock,
        colors: parsedColors,
        sizes: parsedSizes,
        description: draft.description.trim(),
        badge: draft.badge?.trim() || undefined,
        imageUrl: images[0].url,
        images,
      },
      isNew,
    )
    setSaving(false)
    if (message) setError(message)
  }

  const preview = stockLabel(stockState({ listed: draft.listed, stock: Number(draft.stock) || 0 }))

  function changePhoto(index: number, patch: Partial<PhotoDraft>) {
    setPhotos((current) => current.map((photo, item) => (item === index ? { ...photo, ...patch } : photo)))
  }

  function onUrlChange(index: number, value: string) {
    const trimmed = value.trim()
    setPhotos((current) =>
      current.map((photo, item) => {
        if (item !== index) return photo
        if (trimmed) return { ...photo, urlText: value, url: trimmed }
        if (photo.url.startsWith('data:')) return { ...photo, urlText: value }
        return { ...photo, urlText: value, url: '' }
      }),
    )
  }

  async function onPickFile(index: number, file: File) {
    if (!file.type.startsWith('image/')) {
      setError('Choose an image file.')
      return
    }
    try {
      const dataUrl = await readImageFile(file)
      changePhoto(index, { url: dataUrl, urlText: '' })
      setError('')
    } catch {
      setError('Could not read that image.')
    }
  }

  function addPhoto() {
    setPhotos((current) => {
      const used = new Set(current.map((photo) => photo.position))
      const position = photoPositions.find((item) => !used.has(item)) ?? 'Detail'
      return [...current, { url: '', position, urlText: '' }]
    })
  }

  function movePhoto(index: number, delta: number) {
    setPhotos((current) => {
      const target = index + delta
      if (target < 0 || target >= current.length) return current
      const next = [...current]
      const [item] = next.splice(index, 1)
      next.splice(target, 0, item)
      return next
    })
  }

  return (
    <Modal title={isNew ? 'Add product' : draft.name} onClose={onClose}>
      <form onSubmit={onSubmit}>
        <div className="fields">
          <Field label="Name" wide>
            <input value={draft.name} onChange={(event) => update('name', event.target.value)} />
          </Field>
          <Field label="Category">
            <select value={draft.category} onChange={(event) => update('category', event.target.value)}>
              {categories.map((item) => (
                <option key={item}>{item}</option>
              ))}
            </select>
          </Field>
          <Field label="Badge">
            <input value={draft.badge ?? ''} placeholder="BESTSELLER" onChange={(event) => update('badge', event.target.value)} />
          </Field>
          <Field label="Price">
            <input type="number" min={0} value={draft.price || ''} onChange={(event) => update('price', Number(event.target.value))} />
          </Field>
          <Field label="Was">
            <input
              type="number"
              min={0}
              value={draft.oldPrice || ''}
              onChange={(event) => update('oldPrice', Number(event.target.value))}
            />
          </Field>
          <Field label="Stock on hand" hint={`This will show as ${preview}. 0 is out of stock. 1–5 is low stock.`}>
            <input type="number" min={0} value={draft.stock} onChange={(event) => update('stock', Number(event.target.value))} />
          </Field>
          <Field label="Colours">
            <input value={colors} onChange={(event) => setColors(event.target.value)} />
          </Field>
          <Field label="UK sizes" wide>
            <input value={sizes} onChange={(event) => setSizes(event.target.value)} />
          </Field>
          <div className="field span-2">
            <span>Photos</span>
            <div className="photo-list">
              {photos.map((photo, index) => (
                <article className="photo-card" key={index}>
                  <header>
                    <select
                      aria-label={`Position ${index + 1}`}
                      value={photo.position}
                      onChange={(event) => changePhoto(index, { position: event.target.value })}
                    >
                      {photoPositions.map((position) => (
                        <option key={position}>{position}</option>
                      ))}
                      {photoPositions.includes(photo.position as (typeof photoPositions)[number]) ? null : (
                        <option>{photo.position}</option>
                      )}
                    </select>
                    <div className="actions">
                      {index === 0 ? <span className="cover-tag">Cover</span> : null}
                      <button type="button" className="btn small ghost" onClick={() => movePhoto(index, -1)} disabled={index === 0}>
                        Up
                      </button>
                      <button
                        type="button"
                        className="btn small ghost"
                        onClick={() => movePhoto(index, 1)}
                        disabled={index === photos.length - 1}
                      >
                        Down
                      </button>
                      <button
                        type="button"
                        className="btn small danger"
                        onClick={() => setPhotos((current) => current.filter((_, item) => item !== index))}
                      >
                        Remove
                      </button>
                    </div>
                  </header>
                  <div className="photo-row">
                    {photo.url ? (
                      <img className="photo-preview" src={photo.url} alt="" />
                    ) : (
                      <div className="photo-preview placeholder">No photo</div>
                    )}
                    <div className="photo-controls">
                      <label className="btn small ghost file-btn">
                        Upload image
                        <input
                          type="file"
                          accept="image/*"
                          onChange={(event) => {
                            const file = event.target.files?.[0]
                            event.target.value = ''
                            if (file) void onPickFile(index, file)
                          }}
                        />
                      </label>
                      <input
                        value={photo.urlText}
                        placeholder="or paste an image URL"
                        aria-label={`${photo.position} image URL`}
                        onChange={(event) => onUrlChange(index, event.target.value)}
                      />
                    </div>
                  </div>
                </article>
              ))}
            </div>
            <button type="button" className="btn small ghost" onClick={addPhoto}>
              Add another position
            </button>
            <small>Add a photo for each view. The first one is the cover in the catalogue.</small>
          </div>
          <Field label="Description" wide>
            <textarea rows={3} value={draft.description} onChange={(event) => update('description', event.target.value)} />
          </Field>
        </div>
        <label className="check">
          <input type="checkbox" checked={draft.listed} onChange={(event) => update('listed', event.target.checked)} />
          Listed in the shop
        </label>
        <label className="check">
          <input type="checkbox" checked={draft.isNew} onChange={(event) => update('isNew', event.target.checked)} />
          New arrival
        </label>
        <FormError message={error} />
        <div className="actions">
          <button type="button" className="btn ghost" onClick={onClose}>
            Cancel
          </button>
          <button type="submit" className="btn primary" disabled={saving}>
            {saving ? 'Saving…' : 'Save product'}
          </button>
        </div>
      </form>
    </Modal>
  )
}
