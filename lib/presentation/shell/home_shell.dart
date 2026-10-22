import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadCatalog());
  }

  Future<void> _reloadCatalog() async {
    if (!mounted) return;
    final deps = Shop.of(context);
    await deps.catalog.refresh();
  }

  static const _pages = <Widget>[
    HomeScreen(),
    ShopScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([deps.shell, deps.cart]),
      builder: (context, child) {
        final index = deps.shell.index;
        final count = deps.cart.count;
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              for (var i = 0; i < _pages.length; i++)
                Offstage(
                  offstage: index != i,
                  child: TickerMode(
                    enabled: index == i,
                    child: AnimatedOpacity(
                      opacity: index == i ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      child: _pages[i],
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _ShopNav(
            index: index,
            cartCount: count,
            onSelected: (value) {
              if (value != index) HapticFeedback.selectionClick();
              deps.shell.select(value);
              if (value == 0 || value == 1) _reloadCatalog();
            },
          ),
        );
      },
    );
  }
}

class _ShopNav extends StatelessWidget {
  const _ShopNav({
    required this.index,
    required this.cartCount,
    required this.onSelected,
  });

  final int index;
  final int cartCount;
  final ValueChanged<int> onSelected;

  static const _items = <(IconData, IconData, String)>[
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Shop'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Cart'),
    (Icons.local_shipping_outlined, Icons.local_shipping_rounded, 'Orders'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / _items.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    left: index * slot + 6,
                    width: slot - 12,
                    top: 8,
                    bottom: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        Expanded(
                          child: _NavItem(
                            icon: _items[i].$1,
                            selectedIcon: _items[i].$2,
                            label: _items[i].$3,
                            selected: index == i,
                            badge: i == 2 ? cartCount : 0,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.deepGreen : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Badge(
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.deepGreen,
              label: Text('$badge'),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
