import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/entities/shop_models.dart';
import '../viewmodels/shop_view_models.dart';
import 'order_detail_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final ShopOrder order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final pop = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.72, curve: Curves.elasticOut),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: pop,
                child: _SuccessMark(animation: _controller),
              ),
              const SizedBox(height: 22),
              FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(fade),
                  child: Column(
                    children: [
                      const Text('Order placed',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(
                        'Thanks for shopping with Shoe Factory. ${order.eta}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: AppDecor.card(radius: 20),
                        child: Column(
                          children: [
                            _row('Order', order.id),
                            _row('Total', formatRupees(order.total)),
                            _row('Fulfilment',
                                fulfilmentLabel(order.fulfilment)),
                            _row('Payment', paymentLabel(order.paymentMethod)),
                            if (order.paymentReference != null)
                              _row('Razorpay id', order.paymentReference!),
                            _row(order.isPickup ? 'Branch' : 'Deliver to',
                                order.destination),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Track order',
                        icon: Icons.local_shipping_outlined,
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: order.id)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Shop.of(context).shell.select(ShopTab.home);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: const Text('Continue shopping'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 8; i++)
                Transform.rotate(
                  angle: (i / 8) * math.pi * 2 + animation.value * 0.4,
                  child: Transform.translate(
                    offset: Offset(
                        0,
                        -58 *
                            Curves.easeOut.transform(
                                ((animation.value - 0.15).clamp(0.0, 1.0)))),
                    child: Opacity(
                      opacity: (1 - animation.value).clamp(0.0, 1.0),
                      child: Container(
                        width: i.isEven ? 8 : 6,
                        height: i.isEven ? 8 : 6,
                        decoration: BoxDecoration(
                          color: i.isEven ? AppColors.green : AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                    color: AppColors.paleGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 64, color: AppColors.deepGreen),
              ),
            ],
          ),
        );
      },
    );
  }
}
