const base = 'http://127.0.0.1:4010';

async function call(path, { method = 'GET', token, body } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await response.json();
  if (!response.ok) {
    throw new Error(`${method} ${path} -> ${response.status} ${json.error}`);
  }
  return json.data;
}

const health = await call('/health');
if (health.status !== 'ok') throw new Error('health failed');

const session = await call('/api/session', { method: 'POST' });
const token = session.token;
if (session.products.length !== 12) throw new Error('expected 12 products');
if (session.orders.length !== 2) throw new Error('expected seed orders');

const added = await call('/api/cart/items', {
  method: 'POST',
  token,
  body: { productId: 'sf005', size: 8, color: 'Black', quantity: 5 },
});
if (added.cart.items[0].quantity !== 3) throw new Error(`stock cap failed: ${added.cart.items[0].quantity}`);

const coupon = await call('/api/cart/coupon', {
  method: 'POST',
  token,
  body: { code: 'TREND10', pickup: false },
});
if (!coupon.accepted || coupon.quote.discount !== 3000) {
  throw new Error(`coupon failed ${JSON.stringify(coupon.quote)}`);
}

await call(`/api/cart/items/${encodeURIComponent('sf005|8|Black')}`, {
  method: 'DELETE',
  token,
});

const login = await call('/api/auth/login', {
  method: 'POST',
  token,
  body: { email: 'shopper@shoefactory.shop', password: 'trend' },
});
if (login.user.name !== 'Shoe Factory Shopper' || login.addresses.length === 0) {
  throw new Error('login profile missing');
}

const wrong = await fetch(`${base}/api/auth/login`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
  body: JSON.stringify({ email: 'shopper@shoefactory.shop', password: 'nope' }),
});
const wrongJson = await wrong.json();
if (wrong.status !== 400 || wrongJson.error !== 'That password does not match.') {
  throw new Error(`wrong password response ${wrong.status} ${wrongJson.error}`);
}

await call('/api/cart/items', {
  method: 'POST',
  token,
  body: { productId: 'sf007', size: 8, color: 'Black', quantity: 1 },
});
await call('/api/cart/coupon', { method: 'DELETE', token });
const order = await call('/api/orders', {
  method: 'POST',
  token,
  body: {
    fulfilment: 'delivery',
    paymentMethod: 'razorpay',
    contactName: 'Shoe Factory Shopper',
    contactPhone: '9876543210',
    destination: '12, MG Road, Kochi 682001',
  },
});
if (order.total !== 3048) throw new Error(`order total ${order.total}`);

const cart = await call('/api/cart', { token });
if (cart.items.length !== 0) throw new Error('cart was not cleared');

const otp = await call('/api/auth/otp/request', {
  method: 'POST',
  body: { phone: '9123456780' },
});
const verified = await call('/api/auth/otp/verify', {
  method: 'POST',
  token,
  body: { phone: '9123456780', code: otp.code },
});
if (!verified.needsProfile) throw new Error('new number should need a profile');

console.log('API smoke passed');
