import { Navigate, Outlet, Route, Routes } from 'react-router-dom'
import { Shell } from './components/Shell'
import { useAuth } from './data/auth'
import { BranchesPage } from './pages/Branches'
import { CouponsPage } from './pages/Coupons'
import { CustomersPage } from './pages/Customers'
import { DashboardPage } from './pages/Dashboard'
import { LoginPage } from './pages/Login'
import { NoticesPage } from './pages/Notices'
import { OrdersPage } from './pages/Orders'
import { ProductsPage } from './pages/Products'
import { ProfilePage } from './pages/Profile'

function RequireAuth() {
  const { name } = useAuth()
  if (!name) return <Navigate to="/login" replace />
  return <Outlet />
}

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<Shell />}>
          <Route index element={<DashboardPage />} />
          <Route path="products" element={<ProductsPage />} />
          <Route path="orders" element={<OrdersPage />} />
          <Route path="customers" element={<CustomersPage />} />
          <Route path="branches" element={<BranchesPage />} />
          <Route path="coupons" element={<CouponsPage />} />
          <Route path="notices" element={<NoticesPage />} />
          <Route path="profile" element={<ProfilePage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Route>
    </Routes>
  )
}
