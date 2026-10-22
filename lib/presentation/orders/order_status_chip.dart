import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/shop_models.dart';

Color orderStatusColor(OrderStatus status) {
  switch (status) {
    case OrderStatus.completed:
      return AppColors.deepGreen;
    case OrderStatus.cancelled:
      return AppColors.danger;
    case OrderStatus.preparing:
      return AppColors.amber;
    case OrderStatus.confirmed:
    case OrderStatus.onTheWay:
      return AppColors.deepGreen;
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(order.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(order.statusLabel,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
