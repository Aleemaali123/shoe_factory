import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { App } from './App'
import { AuthProvider } from './data/auth'
import { CatalogProvider } from './data/catalog'
import { StoreProvider } from './data/store'
import './styles.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <StoreProvider>
        <CatalogProvider>
          <BrowserRouter>
            <App />
          </BrowserRouter>
        </CatalogProvider>
      </StoreProvider>
    </AuthProvider>
  </StrictMode>,
)
