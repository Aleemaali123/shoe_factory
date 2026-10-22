import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/entities/shop_models.dart';
import '../catalog/catalog_actions.dart';
import '../viewmodels/shop_view_models.dart';
import 'order_detail_screen.dart';
import 'order_status_chip.dart';

class ShoppingHistoryEntry {
  const ShoppingHistoryEntry({required this.order, this.line});

  final ShopOrder order;
  final OrderLine? line;

  String get title => line?.name ?? order.summary;
  String get imageUrl => line?.imageUrl ?? '';

  String get detail {
    final line = this.line;
    if (line == null) return formatDate(order.placedAt);
    return 'UK ${line.size} · ${line.color} · ${formatDate(order.placedAt)}';
  }
}

List<ShoppingHistoryEntry> shoppingHistory(List<ShopOrder> orders) {
  final entries = <ShoppingHistoryEntry>[];
  for (final order in orders) {
    if (order.lines.isEmpty) {
      entries.add(ShoppingHistoryEntry(order: order));
      continue;
    }
    for (final line in order.lines) {
      entries.add(ShoppingHistoryEntry(order: order, line: line));
    }
  }
  return entries;
}

class ShoppingHistorySection extends StatelessWidget {
  const ShoppingHistorySection({super.key, required this.orders});

  final List<ShopOrder> orders;

  @override
  Widget build(BuildContext context) {
    final entries = shoppingHistory(orders);
    final preview = entries.take(3).toList();
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22151715),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Shopping history',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.muted,
                      letterSpacing: .4,
                    ),
                  ),
                ),
                if (entries.isNotEmpty)
                  TextButton(
                    onPressed: () => openShoppingHistory(context),
                    child: const Text('See all'),
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Pairs you buy will show up here.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < preview.length; i++) ...[
              if (i > 0)
                const Divider(height: 1, indent: 84, endIndent: 16, color: AppColors.line),
              ShoppingHistoryTile(entry: preview[i]),
            ],
        ],
      ),
    );
  }
}

void openShoppingHistory(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => const ShoppingHistoryScreen()),
  );
}

class ShoppingHistoryScreen extends StatelessWidget {
  const ShoppingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping history')),
      body: ListenableBuilder(
        listenable: deps.orders,
        builder: (context, child) {
          final entries = shoppingHistory(deps.orders.orders);
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: 'No purchases yet',
              message: 'Shoes you order will stay in this history.',
              actionLabel: 'Start shopping',
              onAction: () {
                deps.shell.select(ShopTab.shop);
                Navigator.pop(context);
              },
            );
          }
          final spent = deps.orders.orders
              .where((order) => order.status != OrderStatus.cancelled)
              .fold<double>(0, (sum, order) => sum + order.total);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                '${entries.length} ${entries.length == 1 ? 'purchase' : 'purchases'} · ${formatRupees(spent)} spent',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < entries.length; i++)
                FadeSlideIn(
                  key: ValueKey('${entries[i].order.id}-$i'),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: const Color(0x22151715),
                      borderRadius: BorderRadius.circular(18),
                      clipBehavior: Clip.antiAlias,
                      child: ShoppingHistoryTile(entry: entries[i], showBuyAgain: true),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ShoppingHistoryTile extends StatelessWidget {
  const ShoppingHistoryTile({
    super.key,
    required this.entry,
    this.showBuyAgain = false,
  });

  final ShoppingHistoryEntry entry;
  final bool showBuyAgain;

  @override
  Widget build(BuildContext context) {
    final line = entry.line;
    final productId = line?.productId;
    final stillSold = productId != null &&
        Shop.of(context).catalog.findById(productId) != null;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: entry.order.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: entry.imageUrl.isEmpty
                    ? const ColoredBox(
                        color: AppColors.paleGreen,
                        child: Icon(Icons.hiking, color: AppColors.deepGreen),
                      )
                    : ProductImage(url: entry.imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatRupees(line?.lineTotal ?? entry.order.total),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      OrderStatusChip(order: entry.order),
                    ],
                  ),
                  if (showBuyAgain && stillSold) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => openProduct(context, productId),
                        child: const Text('Buy again'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
