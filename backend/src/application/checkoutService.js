import { AppError } from '../domain/errors.js';
import { calculate } from '../domain/pricing.js';
import { digits } from '../domain/validators.js';

const fulfilments = new Set(['delivery', 'pickup']);
const payments = new Set(['razorpay', 'cod']);

export function createCheckoutService(orderService, store, paymentService) {
  return {
    quote(device, { fulfilment = 'delivery' } = {}) {
      if (!fulfilments.has(fulfilment)) {
        throw new AppError('Choose home delivery or store pickup.');
      }
      const subtotal = device.cart.items.reduce(
        (sum, item) => sum + item.unitPrice * item.quantity,
        0,
      );
      return calculate({
        subtotal,
        couponCode: device.cart.couponCode,
        pickup: fulfilment === 'pickup',
        coupons: store.coupons(),
      });
    },

    async place(device, input) {
      const fulfilment = input.fulfilment === 'pickup' ? 'pickup' : 'delivery';
      const paymentMethod = payments.has(input.paymentMethod) ? input.paymentMethod : '';
      if (!paymentMethod) throw new AppError('Choose Razorpay or cash on delivery.');
      const contactName = String(input.contactName ?? '').trim();
      const contactPhone = digits(input.contactPhone);
      const destination = String(input.destination ?? '').trim();
      if (contactName.length < 2) throw new AppError('Enter the recipient name.');
      if (destination.length < 5) throw new AppError('Enter where this order should go.');
      if (contactPhone.length !== 10) throw new AppError('Enter a 10-digit phone number.');

      let paymentReference = String(input.paymentReference ?? '').trim() || null;
      if (paymentMethod === 'razorpay') {
        if (!paymentReference) {
          throw new AppError('Complete the Razorpay payment before placing this order.');
        }
        const config = paymentService?.config?.() ?? { enabled: false, mode: null };
        const hasSignature =
          String(input.razorpayOrderId ?? '').trim() &&
          String(input.razorpaySignature ?? '').trim();
        if (config.enabled && hasSignature) {
          const verified = paymentService.verify({
            orderId: input.razorpayOrderId,
            paymentId: paymentReference,
            signature: input.razorpaySignature,
          });
          paymentReference = verified.paymentId;
        } else if (config.enabled && config.mode === 'live') {
          throw new AppError('Complete the Razorpay payment before placing this order.');
        }
        // Test mode may complete via Key Id checkout or local test confirm without a signature.
      }

      return orderService.place(device, {
        fulfilment,
        paymentMethod,
        contactName,
        contactPhone,
        destination,
        paymentReference,
        branchId: input.branchId ?? null,
      });
    },
  };
}
