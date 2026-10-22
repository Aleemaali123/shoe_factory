import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../domain/entities/shop_models.dart';
import '../catalog/catalog_actions.dart';
import '../viewmodels/shop_view_models.dart';
import '../widgets/category_strip.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([deps.shop, deps.wishlist]),
      builder: (context, child) {
        final shop = deps.shop;
        final products = shop.products;
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Shop',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.w900))),
                    IconButton(
                      tooltip: shop.sort.label,
                      onPressed: () => _openSort(context, shop),
                      icon: const Icon(Icons.sort),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(shop.sort.label,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: shop.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Search the collection',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: shop.query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              shop.clearQuery();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              CategoryStrip(
                  categories: shop.categories,
                  selected: shop.category,
                  onSelected: shop.setCategory),
              const SizedBox(height: 8),
              Expanded(
                child: products.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'Nothing in this aisle',
                        message: 'Try another category or a different search.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSort(BuildContext context, CatalogViewModel shop) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Sort by',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              for (final sort in ProductSort.values)
                ListTile(
                  title: Text(sort.label),
                  trailing: shop.sort == sort
                      ? const Icon(Icons.check, color: AppColors.green)
                      : null,
                  onTap: () {
                    shop.setSort(sort);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
