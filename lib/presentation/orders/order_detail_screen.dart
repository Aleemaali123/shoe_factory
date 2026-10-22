import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/shop_messenger.dart';
import '../../domain/entities/shop_models.dart';
import '../viewmodels/shop_view_models.dart';
import 'order_status_chip.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: deps.orders,
      builder: (context, child) {
        final order = deps.orders.byId(orderId);
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order')),
            body: const Center(child: Text('This order could not be found.')),
          );
        }
        final steps = [
          (
            'Order confirmed',
            'We have received your order.',
            Icons.receipt_long
          ),
          (
            'Preparing your pair',
            'The branch is packing your shoes.',
            Icons.inventory_2_outlined
          ),
          (
            order.isPickup ? 'Ready for pickup' : 'Out for delivery',
            order.isPickup
                ? 'Collect it from the branch.'
                : 'Your order is heading to you.',
            order.isPickup
                ? Icons.storefront_outlined
                : Icons.local_shipping_outlined,
          ),
          (
            order.isPickup ? 'Collected' : 'Delivered',
            'Enjoy your new pair.',
            Icons.check_circle_outline,
          ),
        ];
        return Scaffold(
          appBar: AppBar(title: Text(order.id)),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.id,
                        style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Text(order.eta,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20)),
                    const SizedBox(height: 8),
                    OrderStatusChip(order: order),
                    const SizedBox(height: 8),
                    Text(formatDate(order.placedAt),
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('Updates',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 14),
              if (order.status == OrderStatus.cancelled)
                const Text(
                    'This order was cancelled before it left the branch.',
                    style: TextStyle(color: AppColors.muted))
              else
                ...List.generate(steps.length, (index) {
                  final step = steps[index];
                  final done = index <= order.stepIndex;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 42,
                        child: Column(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    done ? AppColors.paleGreen : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: done
                                        ? AppColors.green
                                        : AppColors.line),
                              ),
                              child: Icon(step.$3,
                                  color: done
                                      ? AppColors.deepGreen
                                      : AppColors.muted,
                                  size: 18),
                            ),
                            if (index != steps.length - 1)
                              Container(
                                  width: 2,
                                  height: 42,
                                  color:
                                      done ? AppColors.green : AppColors.line),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step.$1,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: done
                                          ? AppColors.ink
                                          : AppColors.muted)),
                              const SizedBox(height: 3),
                              Text(step.$2,
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              const SizedBox(height: 8),
              const Text('Items',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 10),
              ...order.lines.map(
                (line) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                            width: 64,
                            height: 64,
                            child: ProductImage(url: line.imageUrl)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                                'UK ${line.size} · ${line.color} · ×${line.quantity}',
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(formatRupees(line.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _row('Fulfilment', fulfilmentLabel(order.fulfilment)),
              _row(order.isPickup ? 'Branch' : 'Deliver to', order.destination),
              _row('Payment', paymentLabel(order.paymentMethod)),
              if (order.paymentReference != null)
                _row('Razorpay id', order.paymentReference!),
              if (order.discount > 0)
                _row('Discount', '-${formatRupees(order.discount)}'),
              _row(
                  'Delivery',
                  deliveryFeeLabel(order.deliveryFee,
                      pickup: order.isPickup, subtotal: order.subtotal)),
              _row('Total', formatRupees(order.total)),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Order again',
                icon: Icons.replay,
                onPressed: () async {
                  final added = await deps.orders.reorder(order);
                  deps.cart.sync();
                  if (!context.mounted) return;
                  if (added == 0) {
                    showShopMessage(
                        context, 'Those pairs are no longer available.');
                    return;
                  }
                  deps.shell.select(ShopTab.cart);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
              if (order.canCancel) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _cancel(context, order.id),
                    child: const Text('Cancel order'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 110,
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text(
            'You can cancel while the branch is still preparing it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel order')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final cancelled = await Shop.of(context).orders.cancel(id);
    if (!context.mounted) return;
    await Shop.of(context).notices.refresh();
    if (!context.mounted) return;
    showShopMessage(
        context,
        cancelled
            ? 'Order cancelled.'
            : 'This order can no longer be cancelled.');
  }
}
