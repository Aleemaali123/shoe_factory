import crypto from 'node:crypto';

import { env } from '../config/env.js';
import { AppError } from '../domain/errors.js';

function authHeader(keyId, keySecret) {
  return `Basic ${Buffer.from(`${keyId}:${keySecret}`).toString('base64')}`;
}

export function createPaymentService() {
  const keyId = env.razorpayKeyId;
  const keySecret = env.razorpayKeySecret;
  const enabled = Boolean(keyId && keySecret);

  return {
    config() {
      return {
        enabled,
        keyId: enabled ? keyId : null,
        mode: !keyId
          ? null
          : keyId.startsWith('rzp_test_')
            ? 'test'
            : 'live',
      };
    },

    async createOrder({ amountPaise, receipt } = {}) {
      if (!enabled) {
        throw new AppError(
          'Online payment is not configured. Add RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET to the backend .env file.',
          503,
        );
      }
      const amount = Math.round(Number(amountPaise) || 0);
      if (amount < 100) {
        throw new AppError('Razorpay needs an amount of at least ₹1.');
      }

      const response = await fetch('https://api.razorpay.com/v1/orders', {
        method: 'POST',
        headers: {
          Authorization: authHeader(keyId, keySecret),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount,
          currency: 'INR',
          receipt: String(receipt || `sf_${Date.now()}`).slice(0, 40),
          notes: { source: 'shoe-factory' },
        }),
      });

      const body = await response.json().catch(() => ({}));
      if (!response.ok) {
        const detail =
          body?.error?.description ||
          body?.error?.reason ||
          'Razorpay could not create a payment order.';
        throw new AppError(detail, response.status >= 500 ? 502 : 400);
      }

      return {
        keyId,
        orderId: body.id,
        amount: body.amount,
        currency: body.currency || 'INR',
        mode: keyId.startsWith('rzp_test_') ? 'test' : 'live',
      };
    },

    verify({ orderId, paymentId, signature } = {}) {
      if (!enabled) {
        throw new AppError('Online payment is not configured.', 503);
      }
      const order = String(orderId || '').trim();
      const payment = String(paymentId || '').trim();
      const sig = String(signature || '').trim();
      if (!order || !payment || !sig) {
        throw new AppError('Complete the Razorpay payment before placing this order.');
      }
      const expected = crypto
        .createHmac('sha256', keySecret)
        .update(`${order}|${payment}`)
        .digest('hex');
      const left = Buffer.from(expected);
      const right = Buffer.from(sig);
      if (left.length !== right.length || !crypto.timingSafeEqual(left, right)) {
        throw new AppError('Razorpay payment could not be verified.');
      }
      return { orderId: order, paymentId: payment };
    },
  };
}
