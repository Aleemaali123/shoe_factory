import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({super.key, required this.url, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.paleGreen,
        alignment: Alignment.center,
        child: const Icon(Icons.hiking, size: 42, color: AppColors.deepGreen),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
            builder: (context, value, child) =>
                Opacity(opacity: value, child: child),
            child: child,
          );
        }
        return Container(
          color: const Color(0xFFF0F3F0),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.green),
          ),
        );
      },
    );
  }
}
