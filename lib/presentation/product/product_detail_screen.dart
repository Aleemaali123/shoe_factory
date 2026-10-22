import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_image.dart';
import '../../core/widgets/qty_stepper.dart';
import '../../core/widgets/shop_messenger.dart';
import '../checkout/checkout_screen.dart';
import '../viewmodels/shop_view_models.dart';
import '../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductDetailViewModel? _model;
  final _page = PageController();
  int _image = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_model != null) return;
    _model = ProductDetailViewModel(
      productId: widget.productId,
      catalog: Shop.of(context).catalog,
    );
  }

  @override
  void dispose() {
    _model?.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    if (model == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([model, deps.wishlist]),
      builder: (context, child) {
        final product = model.product;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product details')),
            body: model.loading
                ? const Center(child: CircularProgressIndicator())
                : EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Product unavailable',
                    message: model.error ?? 'This pair is no longer listed.',
                    actionLabel: 'Try again',
                    onAction: model.load,
                  ),
          );
        }
        final wished = deps.wishlist.contains(product.id);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Product details'),
            actions: [
              IconButton(
                onPressed: () {
                  deps.wishlist.toggle(product.id).then((message) {
                    if (message != null && context.mounted) {
                      showShopMessage(context, message);
                    }
                  });
                },
                icon: PopIn(
                  key: ValueKey(wished),
                  child: Icon(
                    wished
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: wished ? AppColors.danger : null,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    height: 320,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _page,
                          itemCount: product.imageUrls.length,
                          onPageChanged: (value) =>
                              setState(() => _image = value),
                          itemBuilder: (context, index) =>
                              ProductImage(url: product.imageUrls[index]),
                        ),
                        if (product.badge != null)
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: AppColors.green,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                product.badge!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10),
                              ),
                            ),
                          ),
                        if (product.imageUrls.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(product.imageUrls.length,
                                  (index) {
                                final active = index == _image;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  width: active ? 18 : 6,
                                  height: 6,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.green
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8)),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              FadeSlideIn(
                index: 1,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.deepGreen,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            fontSize: 11),
                      ),
                      const SizedBox(height: 5),
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.amber, size: 18),
                          Text(
                              ' ${product.rating}  ·  ${product.reviewCount} reviews',
                              style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(formatRupees(product.price),
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 10),
                          if (product.discountPercent > 0) ...[
                            Text(
                              formatRupees(product.oldPrice),
                              style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.muted),
                            ),
                            const SizedBox(width: 8),
                            Text('${product.discountPercent}% OFF',
                                style: const TextStyle(
                                    color: AppColors.deepGreen,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.stock <= 0
                            ? 'Out of stock'
                            : product.lowStock
                                ? 'Only ${product.stock} left'
                                : 'In stock · ready to ship',
                        style: TextStyle(
                            color: product.stock <= 0
                                ? AppColors.danger
                                : product.lowStock
                                    ? AppColors.amber
                                    : AppColors.deepGreen,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 18),
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(product.description,
                          style: const TextStyle(
                              color: AppColors.muted, height: 1.5)),
                      const SizedBox(height: 20),
                      const Text('Colour',
                          style: TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 10,
                        children: product.colors.map((name) {
                          final selected = model.color == name;
                          final swatch = shoeColor(name);
                          final light = name == 'White' || name == 'Beige';
                          return InkWell(
                            onTap: () => model.selectColor(name),
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  width: selected ? 40 : 34,
                                  height: selected ? 40 : 34,
                                  decoration: BoxDecoration(
                                    color: swatch,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: selected
                                            ? AppColors.green
                                            : AppColors.line,
                                        width: selected ? 3 : 1),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.green
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: selected
                                      ? Icon(Icons.check,
                                          size: 16,
                                          color: light
                                              ? AppColors.ink
                                              : Colors.white)
                                      : null,
                                ),
                                const SizedBox(height: 4),
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Size (UK)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          TextButton(
                              onPressed: () => _sizeGuide(context),
                              child: const Text('Size guide')),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.sizes.map((size) {
                          final selected = model.size == size;
                          return ChoiceChip(
                            label: Text('$size'),
                            selected: selected,
                            selectedColor: AppColors.paleGreen,
                            side: selected
                                ? const BorderSide(
                                    color: AppColors.green, width: 1.5)
                                : null,
                            onSelected: (_) => model.selectSize(size),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                              child: Text('Quantity',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          QtyStepper(
                              value: model.inStock ? model.quantity : 0,
                              max: model.maxQty,
                              onChanged: model.setQuantity),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: AppColors.paleGreen,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(
                          children: [
                            Icon(Icons.local_shipping_outlined,
                                color: AppColors.deepGreen),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Home delivery, or free pickup from a Shoe Factory branch.',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text('Reviews',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ...product.reviews.map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: AppColors.amber, size: 16),
                                    Text(
                                        ' ${review.rating}  ·  ${review.author}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(review.comment,
                                    style: const TextStyle(height: 1.4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (model.related.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('You may also like',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 276,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: model.related.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final related = model.related[index];
                              final size = related.sizes.contains(8)
                                  ? 8
                                  : related.sizes.first;
                              return SizedBox(
                                width: 168,
                                child: ProductCard(
                                  product: related,
                                  wished: deps.wishlist.contains(related.id),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                            productId: related.id)),
                                  ),
                                  onWish: () {
                                    deps.wishlist.toggle(related.id).then((message) {
                                      if (message != null && context.mounted) {
                                        showShopMessage(context, message);
                                      }
                                    });
                                  },
                                  onAdd: () async {
                                    final result = await deps.cart.add(related,
                                        size: size,
                                        color: related.colors.first);
                                    if (!context.mounted) return;
                                    showShopMessage(
                                      context,
                                      result.message,
                                      actionLabel:
                                          result.added ? 'View cart' : null,
                                      onAction: () =>
                                          deps.shell.select(ShopTab.cart),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          formatRupees(model.lineTotal),
                          key: ValueKey(model.lineTotal),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const Spacer(),
                      Text('UK ${model.size} · ${model.color}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: OutlinedButton(
                              onPressed: model.inStock
                                  ? () => _add(context, model,
                                      goToCheckout: false)
                                  : null,
                              child: const Text('Add to cart'))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: model.inStock ? 'Buy now' : 'Sold out',
                          icon: Icons.shopping_bag_outlined,
                          onPressed: model.inStock
                              ? () => _add(context, model, goToCheckout: true)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _add(BuildContext context, ProductDetailViewModel model,
      {required bool goToCheckout}) async {
    final product = model.product;
    if (product == null || !model.inStock) return;
    final deps = Shop.of(context);
    final result = await deps.cart.add(product,
        size: model.size, color: model.color, quantity: model.quantity);
    if (!context.mounted) return;
    if (!result.added) {
      showShopMessage(context, result.message);
      return;
    }
    if (goToCheckout) {
      Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => const CheckoutScreen()));
      return;
    }
    showShopMessage(context, result.message, actionLabel: 'View cart',
        onAction: () {
      deps.shell.select(ShopTab.cart);
      Navigator.pop(context);
    });
  }

  void _sizeGuide(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Size guide'),
        content: const Text(
            'Choose your usual UK size. If you are between sizes, the next size up is the safer fit for sneakers and boots. Sandals can follow your regular size.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }
}
