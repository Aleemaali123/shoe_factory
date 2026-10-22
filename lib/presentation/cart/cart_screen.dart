import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/qty_stepper.dart';
import '../../domain/pricing/pricing.dart';
import '../checkout/checkout_screen.dart';
import '../viewmodels/shop_view_models.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: deps.cart,
      builder: (context, child) {
        final cart = deps.cart;
        final quote = cart.quote(pickup: false);
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('My cart',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.w900))),
                    Text('${cart.count} items',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              Expanded(
                child: cart.isEmpty
                    ? EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'Your cart is empty',
                        message:
                            'Find a pair you love and it will show up here.',
                        actionLabel: 'Explore shoes',
                        onAction: () => deps.shell.select(ShopTab.shop),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final product = deps.catalog.findById(item.productId);
                          final maxQty = product == null
                              ? 5
                              : (product.stock < 5 ? product.stock : 5);
                          return FadeSlideIn(
                            key: ValueKey(item.id),
                            index: index,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: AppDecor.card(),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                        width: 94,
                                        height: 94,
                                        child:
                                            ProductImage(url: item.imageUrl)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'UK ${item.size}  ·  ${item.color}',
                                            style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12)),
                                        const SizedBox(height: 6),
                                        Text(formatRupees(item.lineTotal),
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            QtyStepper(
                                              value: item.quantity,
                                              min: 1,
                                              max: maxQty,
                                              onChanged: (value) => cart
                                                  .setQuantity(item.id, value),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  cart.remove(item.id),
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.danger),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (!cart.isEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.line))),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Coupon',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w800))),
                          TextButton(
                              onPressed: () => _couponDialog(context, cart),
                              child: Text(cart.couponCode ?? 'Add code')),
                          if (cart.couponCode != null)
                            IconButton(
                                onPressed: cart.clearCoupon,
                                icon: const Icon(Icons.close, size: 18)),
                        ],
                      ),
                      if (cart.couponMessage != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            cart.couponMessage!,
                            style: TextStyle(
                                color: cart.couponAccepted
                                    ? AppColors.deepGreen
                                    : AppColors.danger,
                                fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final coupon in Pricing.coupons)
                            ActionChip(
                              label: Text(coupon.code),
                              onPressed: () =>
                                  cart.applyCoupon(coupon.code, pickup: false),
                            ),
                        ],
                      ),
                      const Divider(height: 22),
                      _DeliveryMeter(subtotal: quote.subtotal),
                      const SizedBox(height: 10),
                      _summary('Subtotal', formatRupees(quote.subtotal)),
                      if (quote.discount > 0) ...[
                        const SizedBox(height: 6),
                        _summary('Discount', '-${formatRupees(quote.discount)}',
                            valueColor: AppColors.deepGreen),
                      ],
                      const SizedBox(height: 6),
                      _summary(
                          'Delivery',
                          deliveryFeeLabel(quote.deliveryFee,
                              pickup: false, subtotal: quote.subtotal)),
                      const SizedBox(height: 10),
                      _summary('Total', formatRupees(quote.total), bold: true),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Proceed to checkout',
                        icon: Icons.arrow_forward,
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const CheckoutScreen())),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
                  fontSize: bold ? 16 : 13)),
        ),
        Text(
          value,
          style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontSize: bold ? 18 : 13,
              color: valueColor),
        ),
      ],
    );
  }

  Future<void> _couponDialog(BuildContext context, CartViewModel cart) async {
    final controller = TextEditingController(text: cart.couponCode ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply coupon'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'TREND10'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Apply')),
        ],
      ),
    );
    controller.dispose();
    if (code != null && context.mounted) cart.applyCoupon(code, pickup: false);
  }
}

class _DeliveryMeter extends StatelessWidget {
  const _DeliveryMeter({required this.subtotal});

  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final progress = (subtotal / Pricing.freeDeliveryThreshold).clamp(0.0, 1.0);
    final unlocked = progress >= 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: AppColors.paleGreen,
              color: unlocked ? AppColors.green : AppColors.deepGreen,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          unlocked
              ? 'Free delivery unlocked'
              : 'Add ${formatRupees(Pricing.freeDeliveryThreshold - subtotal)} more for free delivery',
          style: TextStyle(
            color: unlocked ? AppColors.deepGreen : AppColors.muted,
            fontSize: 12,
            fontWeight: unlocked ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
