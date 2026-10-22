import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { stockLabel, stockState } from '../lib/stock'
import type { Product } from '../types'
import { adjustProductStock, createProduct, listProducts, removeProduct, updateProduct } from './catalogApi'

type Catalog = {
  products: Product[]
  loading: boolean
  error: string
  flash: string | null
  dismissFlash: () => void
  refresh: () => Promise<void>
  saveProduct: (product: Product, creating: boolean) => Promise<void>
  deleteProduct: (id: string) => Promise<void>
  adjustStock: (id: string, delta: number) => Promise<void>
}

const CatalogContext = createContext<Catalog | null>(null)

export function CatalogProvider({ children }: { children: ReactNode }) {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [flash, setFlash] = useState<string | null>(null)

  const refresh = useCallback(async () => {
    try {
      setProducts(await listProducts())
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not load products.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void refresh()
  }, [refresh])

  useEffect(() => {
    if (!flash) return
    const timer = window.setTimeout(() => setFlash(null), 2600)
    return () => window.clearTimeout(timer)
  }, [flash])

  const catalog = useMemo<Catalog>(() => {
    function remember(product: Product) {
      setProducts((current) => {
        const index = current.findIndex((item) => item.id === product.id)
        const next = [...current]
        if (index >= 0) next[index] = product
        else next.unshift(product)
        return next
      })
    }

    return {
      products,
      loading,
      error,
      flash,
      dismissFlash: () => setFlash(null),
      refresh,
      saveProduct: async (product, creating) => {
        const saved = creating ? await createProduct(product) : await updateProduct(product)
        remember(saved)
        setError('')
        setFlash(`${saved.name} saved · ${stockLabel(stockState(saved))}.`)
      },
      deleteProduct: async (id) => {
        try {
          const removed = await removeProduct(id)
          setProducts((current) => current.filter((item) => item.id !== id))
          setError('')
          setFlash(`${removed.name} removed.`)
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Could not remove that product.')
        }
      },
      adjustStock: async (id, delta) => {
        try {
          const saved = await adjustProductStock(id, delta)
          remember(saved)
          setError('')
          setFlash(`${saved.name} · ${saved.stock} on hand · ${stockLabel(stockState(saved))}.`)
        } catch (err) {
          setError(err instanceof Error ? err.message : 'Could not update stock.')
        }
      },
    }
  }, [products, loading, error, flash, refresh])

  return <CatalogContext.Provider value={catalog}>{children}</CatalogContext.Provider>
}

export function useCatalog() {
  const catalog = useContext(CatalogContext)
  if (!catalog) throw new Error('useCatalog must be used inside CatalogProvider')
  return catalog
}
