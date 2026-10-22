import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shop_messenger.dart';
import '../../domain/entities/shop_models.dart';
import '../orders/order_detail_screen.dart';
import '../product/product_detail_screen.dart';
import '../viewmodels/shop_view_models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _dismissed = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Shop.of(context).notices.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final noticesModel = Shop.of(context).notices;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: noticesModel,
            builder: (context, child) {
              if (noticesModel.unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: noticesModel.markAllRead,
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: noticesModel,
        builder: (context, child) {
          final notices = [
            for (final notice in noticesModel.notices)
              if (!_dismissed.contains(notice.id)) notice,
          ];
          return RefreshIndicator(
            onRefresh: noticesModel.refresh,
            child: notices.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 72),
                      EmptyState(
                        icon: Icons.notifications_none,
                        title: 'No notifications',
                        message:
                            'Offers and order updates from the shop will show up here.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: notices.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notice = notices[index];
                      return Dismissible(
                        key: ValueKey(notice.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() => _dismissed.add(notice.id));
                          noticesModel.dismiss(notice.id);
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        child: _NoticeCard(
                          notice: notice,
                          onTap: () => _open(context, notice),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Future<void> _open(BuildContext context, ShopNotice notice) async {
    final deps = Shop.of(context);
    await deps.notices.markRead(notice.id);
    if (!context.mounted) return;
    switch (notice.kind) {
      case 'order':
        final id = notice.targetId;
        if (id.isEmpty || deps.orders.byId(id) == null) {
          showShopMessage(context, 'That order is not on this device.');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => OrderDetailScreen(orderId: id)),
        );
      case 'product':
        final id = notice.targetId;
        if (id.isEmpty || deps.catalog.findById(id) == null) {
          showShopMessage(context, 'That pair is no longer listed.');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(productId: id)),
        );
      case 'offer':
        final code = notice.targetId;
        if (code.isEmpty) return;
        await deps.cart.applyCoupon(code, pickup: false);
        if (!context.mounted) return;
        if (!deps.cart.couponAccepted) {
          showShopMessage(
            context,
            deps.cart.couponMessage ?? 'That coupon could not be applied.',
          );
          return;
        }
        deps.shell.select(ShopTab.cart);
        Navigator.pop(context);
      default:
        break;
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final ShopNotice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notice.read;
    return Material(
      color: unread ? AppColors.paleGreen : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? AppColors.deepGreen : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_icon(notice.kind), color: AppColors.deepGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.deepGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    notice.timeLabel,
                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notice.body,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              if (_hint(notice) != null) ...[
                const SizedBox(height: 8),
                Text(
                  _hint(notice)!,
                  style: const TextStyle(
                    color: AppColors.deepGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

IconData _icon(String kind) {
  switch (kind) {
    case 'order':
      return Icons.local_shipping_outlined;
    case 'offer':
      return Icons.sell_outlined;
    case 'product':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.notifications_none;
  }
}

String? _hint(ShopNotice notice) {
  switch (notice.kind) {
    case 'order':
      return notice.targetId.isEmpty ? null : 'Open ${notice.targetId}';
    case 'offer':
      return notice.targetId.isEmpty ? null : 'Apply ${notice.targetId}';
    case 'product':
      return notice.targetId.isEmpty ? null : 'Open this pair';
    default:
      return null;
  }
}
