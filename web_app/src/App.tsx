import { Navigate, Route, Routes } from 'react-router-dom'
import { Shell } from './components/Shell'
import { AccountPage } from './pages/Account'
import { BranchesPage } from './pages/Branches'
import { CartPage } from './pages/Cart'
import { CheckoutPage } from './pages/Checkout'
import { HelpPage } from './pages/Help'
import { HomePage } from './pages/Home'
import { NoticesPage } from './pages/Notices'
import { OrderPage } from './pages/Order'
import { OrdersPage } from './pages/Orders'
import { PoliciesPage } from './pages/Policies'
import { ProductPage } from './pages/Product'
import { ShopPage } from './pages/Shop'
import { SignInPage } from './pages/SignIn'
import { WishlistPage } from './pages/Wishlist'

export function App() {
  return (
    <Routes>
      <Route element={<Shell />}>
        <Route index element={<HomePage />} />
        <Route path="shop" element={<ShopPage />} />
        <Route path="product/:id" element={<ProductPage />} />
        <Route path="cart" element={<CartPage />} />
        <Route path="checkout" element={<CheckoutPage />} />
        <Route path="orders" element={<OrdersPage />} />
        <Route path="orders/:id" element={<OrderPage />} />
        <Route path="wishlist" element={<WishlistPage />} />
        <Route path="account" element={<AccountPage />} />
        <Route path="sign-in" element={<SignInPage />} />
        <Route path="notices" element={<NoticesPage />} />
        <Route path="branches" element={<BranchesPage />} />
        <Route path="help" element={<HelpPage />} />
        <Route path="policies" element={<PoliciesPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
    </Routes>
  )
}
