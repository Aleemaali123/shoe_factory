import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/widgets/empty_state.dart';
import '../catalog/catalog_actions.dart';
import '../viewmodels/shop_view_models.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: ListenableBuilder(
        listenable: deps.wishlist,
        builder: (context, child) {
          final products = deps.wishlist.products;
          if (products.isEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: 'No saved pairs',
              message: 'Tap the heart on a shoe to keep it here.',
              actionLabel: 'Browse the shop',
              onAction: () {
                deps.shell.select(ShopTab.shop);
                Navigator.pop(context);
              },
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => FadeSlideIn(
              key: ValueKey(products[index].id),
              index: index,
              child: catalogCard(context, products[index]),
            ),
          );
        },
      ),
    );
  }
}
