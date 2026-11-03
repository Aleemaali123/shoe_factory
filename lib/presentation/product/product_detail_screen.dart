import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../domain/entities/shop_models.dart';
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
              _ProductGallery(
                product: product,
                color: model.color,
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
                      if (product.colors.isNotEmpty) ...[
                        const SizedBox(height: 18),
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
                              borderRadius: BorderRadius.circular(12),
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
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: selected
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                          color: selected
                                              ? AppColors.deepGreen
                                              : AppColors.ink)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      Text(product.description,
                          style: const TextStyle(
                              color: AppColors.muted, height: 1.5)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: Text(sizeHeading(product.category),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16))),
                          TextButton(
                              onPressed: () =>
                                  _sizeGuide(context, product.category),
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
                      Text(
                          '${sizeOption(product.category, model.size)} · ${model.color}',
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

  void _sizeGuide(BuildContext context, String category) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Size guide'),
        content: Text(sizeGuide(category)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({
    required this.product,
    required this.color,
  });

  final Product product;
  final String color;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final _page = PageController();
  final _thumbs = ScrollController();
  int _index = 0;

  @override
  void didUpdateWidget(_ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    final colorChanged = oldWidget.color != widget.color;
    final productChanged = oldWidget.product.id != widget.product.id;
    if (!colorChanged && !productChanged) return;
    _index = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_page.hasClients) _page.jumpToPage(0);
      if (_thumbs.hasClients) _thumbs.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _thumbs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shots = product.galleryFor(widget.color);
    final tint = product.recolorGallery(widget.color);
    final safeIndex = shots.isEmpty ? 0 : _index.clamp(0, shots.length - 1);
    final current = shots.isEmpty ? null : shots[safeIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 340,
              child: Stack(
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: PageView.builder(
                      controller: _page,
                      itemCount: shots.length,
                      onPageChanged: (value) {
                        setState(() => _index = value);
                        _revealThumb(value);
                      },
                      itemBuilder: (context, index) => _framed(
                        shots[index].url,
                        tint: tint,
                        fit: BoxFit.contain,
                      ),
                    ),
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
                  if (shots.length > 1)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xCC151715),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${safeIndex + 1}/${shots.length}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (current != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.color.isEmpty
                  ? current.label
                  : '${widget.color} · ${current.label}',
              style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12),
            ),
          ],
          if (shots.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView.separated(
                controller: _thumbs,
                scrollDirection: Axis.horizontal,
                itemCount: shots.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final active = index == safeIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _index = index);
                      _page.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: active ? AppColors.green : AppColors.line,
                          width: active ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _framed(
                          shots[index].url,
                          tint: tint,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _framed(String url, {required bool tint, required BoxFit fit}) {
    final image = SizedBox.expand(child: ProductImage(url: url, fit: fit));
    if (!tint) return image;
    return ColorFiltered(
      colorFilter: _colorwayFilter(widget.color),
      child: image,
    );
  }

  void _revealThumb(int index) {
    if (!_thumbs.hasClients) return;
    final target = (index * 80.0) - 40;
    final max = _thumbs.position.maxScrollExtent;
    _thumbs.animateTo(
      target.clamp(0, max),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }
}

ColorFilter _colorwayFilter(String name) {
  switch (name) {
    case 'Black':
      return const ColorFilter.matrix(<double>[
        0.22, 0.22, 0.22, 0, 8,
        0.22, 0.22, 0.22, 0, 8,
        0.22, 0.22, 0.22, 0, 8,
        0, 0, 0, 1, 0,
      ]);
    case 'White':
      return const ColorFilter.matrix(<double>[
        0.35, 0.35, 0.35, 0, 120,
        0.35, 0.35, 0.35, 0, 120,
        0.35, 0.35, 0.35, 0, 120,
        0, 0, 0, 1, 0,
      ]);
    case 'Grey':
      return const ColorFilter.matrix(<double>[
        0.4, 0.4, 0.4, 0, 28,
        0.4, 0.4, 0.4, 0, 28,
        0.4, 0.4, 0.4, 0, 28,
        0, 0, 0, 1, 0,
      ]);
    case 'Green':
      return const ColorFilter.mode(Color(0xFF1F7A3A), BlendMode.modulate);
    case 'Navy':
      return const ColorFilter.mode(Color(0xFF1A237E), BlendMode.modulate);
    case 'Brown':
      return const ColorFilter.mode(Color(0xFF6D4C41), BlendMode.modulate);
    case 'Beige':
      return const ColorFilter.mode(Color(0xFFC4A574), BlendMode.modulate);
    case 'Red':
      return const ColorFilter.mode(Color(0xFFD32F2F), BlendMode.modulate);
    default:
      return ColorFilter.mode(shoeColor(name), BlendMode.modulate);
  }
}
