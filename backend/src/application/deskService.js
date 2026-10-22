import crypto from 'node:crypto';

import { AppError } from '../domain/errors.js';
import { digits } from '../domain/validators.js';

const kinds = new Set(['percent', 'flat', 'shipping']);
const noticeKinds = new Set(['info', 'offer', 'product', 'order']);
const statuses = new Set(['confirmed', 'preparing', 'onTheWay', 'completed', 'cancelled']);

export function createDeskService(store) {
  return {
    coupons() {
      return store.coupons();
    },

    shopCoupons() {
      return store.shopCoupons();
    },

    saveCoupon(input, previousCode) {
      const coupon = normalizeCoupon(input);
      const key = String(previousCode ?? coupon.code).trim().toUpperCase();
      if (store.coupons().some((item) => item.code === coupon.code && item.code !== key)) {
        throw new AppError('That coupon code already exists.');
      }
      return store.saveCoupon(coupon, key);
    },

    deleteCoupon(code) {
      if (!store.deleteCoupon(code)) throw new AppError('That coupon could not be found.', 404);
      return { code: String(code).trim().toUpperCase() };
    },

    branches() {
      return store.branches();
    },

    saveBranch(input, { creating = false } = {}) {
      const branch = normalizeBranch(input);
      if (creating && store.branches().some((item) => item.id === branch.id)) {
        throw new AppError('That branch id already exists.');
      }
      return store.saveBranch(branch);
    },

    deleteBranch(id) {
      if (store.branches().length <= 1) throw new AppError('Keep at least one branch.');
      if (!store.deleteBranch(id)) throw new AppError('That branch could not be found.', 404);
      return { id };
    },

    notices() {
      return store.notices();
    },

    saveNotice(input) {
      const notice = normalizeNotice(store, input);
      return store.saveNotice(notice);
    },

    deleteNotice(id) {
      if (!store.deleteNotice(id)) throw new AppError('That notice could not be found.', 404);
      return { id };
    },

    orders() {
      return store.adminOrders();
    },

    setOrderStatus(id, status) {
      if (!statuses.has(status)) throw new AppError('Choose a valid order status.');
      const order = store.setOrderStatus(id, status);
      if (!order) throw new AppError('That order could not be found.', 404);
      return order;
    },

    customers() {
      return store.adminCustomers();
    },

    saveCustomer(id, input) {
      const name = String(input.name ?? '').trim();
      const email = String(input.email ?? '').trim();
      const phone = digits(input.phone);
      const city = String(input.city ?? '').trim();
      if (name.length < 2) throw new AppError('Enter a name.');
      const guest = String(id).startsWith('guest-');
      if (!guest && (!email.includes('@') || !email.includes('.'))) {
        throw new AppError('Enter a valid email.');
      }
      if (email && (!email.includes('@') || !email.includes('.'))) {
        throw new AppError('Enter a valid email.');
      }
      if (!/^[6-9]\d{9}$/.test(phone)) throw new AppError('Enter a 10-digit mobile number.');
      if (!guest) {
        const current = store.accountById(id);
        if (!current) throw new AppError('That customer could not be found.', 404);
        const takenEmail = store.accountByEmail(email);
        if (takenEmail && takenEmail.id !== id) throw new AppError('Another account already uses that email.');
        const takenPhone = store.accountByPhone(phone);
        if (takenPhone && takenPhone.id !== id) {
          throw new AppError('Another account already uses that mobile number.');
        }
      }
      const saved = store.saveCustomer({ id, name, email, phone, city });
      if (!saved) throw new AppError('That customer could not be found.', 404);
      return saved;
    },

    profile() {
      return store.adminProfile();
    },

    updateProfile(input) {
      const name = String(input.name ?? '').trim();
      const email = String(input.email ?? '').trim();
      const phone = digits(input.phone);
      if (name.length < 2) throw new AppError('Enter your name.');
      if (!email.includes('@') || !email.includes('.')) throw new AppError('Enter a valid email.');
      if (!/^[6-9]\d{9}$/.test(phone)) throw new AppError('Enter a 10-digit mobile number.');
      return store.saveAdmin({ name, email, phone });
    },

    requestOtp(phone) {
      const mobile = digits(phone);
      if (!/^[6-9]\d{9}$/.test(mobile)) throw new AppError('Enter a 10-digit mobile number.');
      if (mobile !== store.adminProfile().phone) {
        throw new AppError('That mobile number is not on the admin desk.');
      }
      const code = String(crypto.randomInt(100000, 1000000));
      store.saveOtp(mobile, code, new Date(Date.now() + 5 * 60 * 1000).toISOString());
      return { code };
    },

    verifyOtp(phone, code) {
      const mobile = digits(phone);
      const pending = store.otp(mobile);
      if (!pending || mobile !== store.adminProfile().phone) {
        throw new AppError('Request a code for this mobile number first.');
      }
      if (new Date(pending.expiresAt).getTime() < Date.now()) {
        throw new AppError('That code has expired. Request a new one.');
      }
      if (pending.code !== digits(code)) throw new AppError('That code does not match.');
      store.clearOtp(mobile);
      return { profile: store.adminProfile() };
    },

    restore() {
      store.restoreDesk();
      return {
        branches: store.branches(),
        notices: store.notices(),
        coupons: store.coupons(),
      };
    },
  };
}

function normalizeCoupon(input) {
  const code = String(input.code ?? '').trim().toUpperCase();
  if (!/^[A-Z0-9]{3,16}$/.test(code)) throw new AppError('Use 3–16 letters or numbers.');
  const kind = String(input.kind ?? '');
  if (!kinds.has(kind)) throw new AppError('Choose a coupon kind.');
  const minSubtotal = Math.max(0, Number(input.minSubtotal) || 0);
  let value = 0;
  if (kind === 'percent') {
    value = Number(input.value);
    if (!Number.isFinite(value) || value < 1 || value > 100) {
      throw new AppError('Enter a percent from 1 to 100.');
    }
  } else if (kind === 'flat') {
    value = Number(input.value);
    if (!Number.isFinite(value) || value < 1) throw new AppError('Enter an amount in rupees.');
  }
  return {
    code,
    label: String(input.label ?? '').trim() || code,
    kind,
    value,
    minSubtotal,
    active: input.active !== false,
  };
}

function normalizeBranch(input) {
  const id = String(input.id ?? '').trim().toLowerCase();
  const name = String(input.name ?? '').trim();
  const address = String(input.address ?? '').trim();
  const hours = String(input.hours ?? '').trim();
  const phone = String(input.phone ?? '').trim();
  if (!/^[a-z0-9-]{2,24}$/.test(id)) throw new AppError('Give the branch an id.');
  if (name.length < 2) throw new AppError('Enter the branch name.');
  if (address.length < 4) throw new AppError('Enter the branch address.');
  if (!hours) throw new AppError('Enter the opening hours.');
  if (!phone) throw new AppError('Enter a phone number.');
  return { id, name, address, hours, phone };
}

function normalizeNotice(store, input) {
  const notice = {
    id: String(input.id ?? '').trim() || `n${crypto.randomUUID().slice(0, 8)}`,
    title: String(input.title ?? '').trim(),
    body: String(input.body ?? '').trim(),
    timeLabel: String(input.timeLabel ?? 'Today').trim() || 'Today',
    kind: String(input.kind ?? 'info').trim() || 'info',
    targetId: String(input.targetId ?? '').trim(),
  };
  if (notice.title.length < 2) throw new AppError('Enter a notice title.');
  if (notice.body.length < 2) throw new AppError('Enter the notice.');
  if (!noticeKinds.has(notice.kind)) throw new AppError('Choose what this notice opens.');
  if (notice.kind === 'info') {
    notice.targetId = '';
    return notice;
  }
  if (notice.kind === 'offer') notice.targetId = notice.targetId.toUpperCase();
  if (notice.targetId.length < 2) {
    throw new AppError(notice.kind === 'offer'
      ? 'Enter the coupon code this notice should apply.'
      : notice.kind === 'product'
        ? 'Enter the product id this notice should open.'
        : 'Enter the order id this notice should open.');
  }
  if (notice.kind === 'offer' && !store.coupons().some((coupon) => coupon.code === notice.targetId && coupon.active !== false)) {
    throw new AppError('That coupon is not active.');
  }
  if (notice.kind === 'product' && !store.product(notice.targetId)) {
    throw new AppError('That product could not be found.');
  }
  if (notice.kind === 'order' && !store.adminOrders().some((order) => order.id === notice.targetId)) {
    throw new AppError('That order could not be found.');
  }
  return notice;
}
