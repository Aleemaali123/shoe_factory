import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 56});

  /// Height of the wordmark. Width follows the artwork.
  final double size;

  static const aspectRatio = 948 / 452;

  @override
  Widget build(BuildContext context) {
    final width = size * aspectRatio;
    return Image.asset(
      AppAssets.logo,
      width: width,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: width,
        height: size,
        child: Icon(Icons.storefront,
            color: AppColors.deepGreen, size: size * 0.7),
      ),
    );
  }
}
