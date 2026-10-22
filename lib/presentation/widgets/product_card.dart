import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/entities/shop_models.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.wished,
    required this.onTap,
    required this.onAdd,
    required this.onWish,
  });

  final Product product;
  final bool wished;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onWish;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wished = widget.wished;
    final badge = product.badge ??
        (product.discountPercent > 0
            ? '${product.discountPercent}% OFF'
            : null);
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          elevation: _pressed ? 1 : 3,
          shadowColor: const Color(0x33151715),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: ProductImage(url: product.imageUrl),
                        ),
                      ),
                      if (badge != null)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              badge,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .3),
                            ),
                          ),
                        ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child:
                            _WishButton(wished: wished, onWish: widget.onWish),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.amber, size: 15),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${product.rating} (${product.reviewCount})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(formatRupees(product.price),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14)),
                                if (product.discountPercent > 0)
                                  Text(
                                    formatRupees(product.oldPrice),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                        decoration: TextDecoration.lineThrough),
                                  ),
                              ],
                            ),
                          ),
                          _AddButton(onAdd: widget.onAdd),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WishButton extends StatelessWidget {
  const _WishButton({required this.wished, required this.onWish});

  final bool wished;
  final VoidCallback onWish;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x33151715),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onWish();
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: PopIn(
            key: ValueKey(wished),
            child: Icon(
              wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 16,
              color: wished ? AppColors.danger : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.green,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.deepGreen.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onAdd();
        },
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
