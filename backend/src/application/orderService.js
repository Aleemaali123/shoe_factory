import { AppError } from '../domain/errors.js';
import { calculate } from '../domain/pricing.js';

const cancellable = new Set(['confirmed', 'preparing']);

export function createOrderService(store, cartService) {
  return {
    list(device) {
      return device.orders;
    },

    find(device, id) {
      return device.orders.find((order) => order.id === id) ?? null;
    },

    place(device, input) {
      const items = device.cart.items;
      if (!items.length) throw new AppError('Your cart is empty.');
      const subtotal = items.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0);
      const pickup = input.fulfilment === 'pickup';
      const quote = calculate({
        subtotal,
        couponCode: device.cart.couponCode,
        pickup,
      });
      const order = {
        id: store.nextOrderId(),
        placedAt: new Date().toISOString(),
        lines: items.map((item) => ({
          productId: item.productId,
          name: item.name,
          imageUrl: item.imageUrl,
          unitPrice: item.unitPrice,
          color: item.color,
          size: item.size,
          quantity: item.quantity,
        })),
        subtotal: quote.subtotal,
        discount: quote.discount,
        deliveryFee: quote.deliveryFee,
        total: quote.total,
        fulfilment: input.fulfilment || 'delivery',
        paymentMethod: input.paymentMethod || 'razorpay',
        status: 'confirmed',
        destination: String(input.destination ?? ''),
        contactName: String(input.contactName ?? ''),
        contactPhone: String(input.contactPhone ?? ''),
        couponCode: quote.couponCode,
        paymentReference: input.paymentReference ?? null,
      };
      device.orders.unshift(order);
      cartService.clear(device);
      return order;
    },

    cancel(device, id) {
      const order = this.find(device, id);
      if (!order || !cancellable.has(order.status)) return { cancelled: false, order };
      order.status = 'cancelled';
      store.save();
      return { cancelled: true, order };
    },

    reorder(device, id) {
      const order = this.find(device, id);
      if (!order) throw new AppError('That order could not be found.', 404);
      let units = 0;
      for (const line of order.lines) {
        if (!store.product(line.productId)) continue;
        const result = cartService.add(device, {
          productId: line.productId,
          size: line.size,
          color: line.color,
          quantity: line.quantity,
        });
        if (result.added) units += line.quantity;
      }
      return { units, cart: resultCart(device) };
    },
  };
}

function resultCart(device) {
  return { items: device.cart.items, couponCode: device.cart.couponCode };
}
