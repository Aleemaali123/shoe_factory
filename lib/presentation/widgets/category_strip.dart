import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class CategoryStrip extends StatelessWidget {
  const CategoryStrip(
      {super.key,
      required this.categories,
      required this.selected,
      required this.onSelected});

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final name = categories[index];
          final active = selected == name;
          return InkWell(
            onTap: () {
              if (!active) HapticFeedback.selectionClick();
              onSelected(name);
            },
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  AnimatedScale(
                    scale: active ? 1.06 : 1,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: active ? AppColors.green : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.green.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : AppDecor.shadow,
                      ),
                      child: Icon(_icon(name),
                          color: active ? Colors.white : AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 7),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontSize: 11,
                      color: active ? AppColors.deepGreen : AppColors.ink,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    ),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _icon(String name) {
    switch (name) {
      case 'Sneakers':
        return Icons.directions_run_rounded;
      case 'Sports':
        return Icons.sports_rounded;
      case 'Casual':
        return Icons.style_rounded;
      case 'Formal':
        return Icons.business_center_rounded;
      case 'Sandals':
        return Icons.beach_access_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
