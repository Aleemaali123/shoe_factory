import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

import { AppError } from '../../domain/errors.js';
import { hashPassword } from '../security/passwords.js';
import { createSeed, sampleOrders } from './seed.js';

export class JsonStore {
  constructor(filePath, data) {
    this.filePath = filePath;
    this.data = data;
  }

  save() {
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2));
  }

  products() {
    return this.data.products;
  }

  product(id) {
    return this.data.products.find((item) => item.id === id) ?? null;
  }

  saveProduct(product) {
    const index = this.data.products.findIndex((item) => item.id === product.id);
    if (index >= 0) this.data.products[index] = product;
    else this.data.products.unshift(product);
    this.save();
    return product;
  }

  deleteProduct(id) {
    const before = this.data.products.length;
    this.data.products = this.data.products.filter((item) => item.id !== id);
    if (this.data.products.length === before) return false;
    this.save();
    return true;
  }

  branches() {
    return this.data.branches;
  }

  noticesFor(device) {
    const read = new Set(device.readNoticeIds ?? []);
    return this.data.notices.map((notice) => ({ ...notice, read: read.has(notice.id) }));
  }

  markNoticesRead(device) {
    device.readNoticeIds = this.data.notices.map((notice) => notice.id);
    this.save();
  }

  createDevice() {
    const id = `device-${crypto.randomUUID()}`;
    const device = {
      id,
      linkedAccountId: null,
      cart: { items: [], couponCode: null },
      wishlist: [],
      orders: sampleOrders(),
      readNoticeIds: [],
    };
    this.data.devices[id] = device;
    this.save();
    return device;
  }

  device(id) {
    const device = this.data.devices[id];
    if (!device) throw new AppError('Sign in is required.', 401);
    return device;
  }

  accountById(id) {
    return this.data.accounts.find((account) => account.id === id) ?? null;
  }

  accountByEmail(email) {
    const key = String(email ?? '').trim().toLowerCase();
    return this.data.accounts.find((account) => account.email.toLowerCase() === key) ?? null;
  }

  accountByPhone(phone) {
    return this.data.accounts.find((account) => account.phone === phone) ?? null;
  }

  linkedAccount(device) {
    if (!device.linkedAccountId) return null;
    return this.accountById(device.linkedAccountId);
  }

  link(device, account) {
    device.linkedAccountId = account.id;
    this.ensureHomeAddress(account);
    this.save();
  }

  unlink(device) {
    device.linkedAccountId = null;
    this.save();
  }

  ensureHomeAddress(account) {
    if (account.addresses.length > 0) return;
    account.addresses.push({
      id: 'addr-home',
      label: 'Home',
      name: account.name,
      phone: account.phone,
      line: '12, MG Road',
      city: 'Thiruvananthapuram',
      pincode: '695001',
      isDefault: true,
    });
  }

  saveAccount(account) {
    const index = this.data.accounts.findIndex((item) => item.id === account.id);
    if (index >= 0) this.data.accounts[index] = account;
    else this.data.accounts.push(account);
    this.save();
  }

  nextOrderId() {
    const id = `SF-${this.data.orderSeq}`;
    this.data.orderSeq += 1;
    return id;
  }

  saveOtp(phone, code, expiresAt) {
    this.data.otps[phone] = { code, expiresAt };
    this.save();
  }

  otp(phone) {
    return this.data.otps[phone] ?? null;
  }

  clearOtp(phone) {
    delete this.data.otps[phone];
    this.save();
  }
}

export async function openStore(filePath) {
  if (fs.existsSync(filePath)) {
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    return new JsonStore(path.resolve(filePath), data);
  }
  const passwordHash = await hashPassword('trend');
  const store = new JsonStore(path.resolve(filePath), createSeed({ passwordHash }));
  store.save();
  return store;
}
