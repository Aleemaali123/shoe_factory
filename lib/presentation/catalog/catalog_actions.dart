import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/widgets/shop_messenger.dart';
import '../../domain/entities/shop_models.dart';
import '../product/product_detail_screen.dart';
import '../viewmodels/shop_view_models.dart';
import '../widgets/product_card.dart';
import '../branches/branch_screen.dart';

void openProduct(BuildContext context, String productId) {
  Navigator.push(
      context,
      MaterialPageRoute<void>(
          builder: (_) => ProductDetailScreen(productId: productId)));
}

Future<void> quickAdd(BuildContext context, Product product) async {
  final deps = Shop.of(context);
  final result = await deps.cart.add(
    product,
    size: product.sizes.contains(8) ? 8 : product.sizes.first,
    color: product.colors.first,
  );
  if (!context.mounted) return;
  showShopMessage(
    context,
    result.message,
    actionLabel: result.added ? 'View cart' : null,
    onAction: () => deps.shell.select(ShopTab.cart),
  );
}

Widget catalogCard(BuildContext context, Product product) {
  final deps = Shop.of(context);
  return ProductCard(
    product: product,
    wished: deps.wishlist.contains(product.id),
    onTap: () => openProduct(context, product.id),
    onWish: () => deps.wishlist.toggle(product.id),
    onAdd: () {
      quickAdd(context, product);
    },
  );
}

Future<void> chooseBranch(BuildContext context) async {
  final deps = Shop.of(context);
  final id = await Navigator.push<String>(
    context,
    MaterialPageRoute(
        builder: (_) => BranchScreen(selectedId: deps.branches.selected.id)),
  );
  if (id != null && context.mounted) deps.branches.select(id);
}
