import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/entities/shop_models.dart';
import '../viewmodels/shop_view_models.dart';
import 'order_detail_screen.dart';
import 'order_status_chip.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: deps.orders,
      builder: (context, child) {
        final orders = deps.orders.orders;
        return SafeArea(
          child: orders.isEmpty
              ? EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No orders yet',
                  message: 'When you place an order, you can track it here.',
                  actionLabel: 'Start shopping',
                  onAction: () => deps.shell.select(ShopTab.shop),
                )
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Text('My orders',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Track purchases and buy a pair again',
                        style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 18),
                    for (var i = 0; i < orders.length; i++)
                      FadeSlideIn(
                        key: ValueKey(orders[i].id),
                        index: i,
                        child: _OrderCard(order: orders[i]),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final lines = order.lines;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppDecor.card(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LeadImage(line: lines.isEmpty ? null : lines.first),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  order.id,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              OrderStatusChip(order: order),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lines.isEmpty ? order.summary : lines.first.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            lines.isEmpty
                                ? formatDate(order.placedAt)
                                : 'UK ${lines.first.size} · ${lines.first.color}',
                            style: const TextStyle(
                                color: AppColors.muted, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatRupees(order.total),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 17),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lines.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: lines.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final line = lines[index];
                        return _Thumb(
                          url: line.imageUrl,
                          selected: index == 0,
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${formatDate(order.placedAt)} · ${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                    const Text(
                      'View order',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.deepGreen),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: order.id)),
    );
  }
}

class _LeadImage extends StatelessWidget {
  const _LeadImage({required this.line});

  final OrderLine? line;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 92,
        height: 92,
        child: line == null
            ? const ColoredBox(
                color: AppColors.paleGreen,
                child: Icon(Icons.hiking, color: AppColors.deepGreen),
              )
            : ProductImage(url: line!.imageUrl),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.selected});

  final String url;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.green : AppColors.line,
          width: selected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: ProductImage(url: url),
      ),
    );
  }
}
