import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shop_context.dart';
import '../../core/motion/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/product_image.dart';
import '../../domain/entities/shop_models.dart';
import '../catalog/catalog_actions.dart';
import '../notifications/notifications_screen.dart';
import 'location_sheet.dart';
import '../viewmodels/shop_view_models.dart';
import '../widgets/category_strip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  final _banner = PageController();
  int _bannerIndex = 0;
  int _bannerPages = 0;
  Timer? _bannerTimer;

  static const _bannerInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Shop.of(context).location.ensureDetected();
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(_bannerInterval, (_) => _advanceBanner());
  }

  void _advanceBanner() {
    if (!mounted || !_banner.hasClients || _bannerPages < 2) return;
    final next = (_bannerIndex + 1) % _bannerPages;
    _banner.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _search.dispose();
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: AppColors.canvas,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            deps.home,
            deps.branches,
            deps.location,
            deps.wishlist,
            deps.notices,
          ]),
          builder: (context, child) {
            final home = deps.home;
            final browsing = home.query.isEmpty && home.category == 'All';
            final products = home.products;
            return Column(
              children: [
                _header(context, deps),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (browsing)
                        const SliverToBoxAdapter(child: _TrustRow()),
                      if (browsing)
                        SliverToBoxAdapter(child: _bannerPager(context)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text('Shop by category',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900)),
                              ),
                              TextButton(
                                onPressed: () {
                                  deps.shop.setCategory('All');
                                  deps.shop.clearQuery();
                                  deps.shell.select(ShopTab.shop);
                                },
                                child: const Text('View all'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: CategoryStrip(
                          categories: home.categories,
                          selected: home.category,
                          onSelected: home.setCategory,
                        ),
                      ),
                      if (browsing && home.deals.isNotEmpty) ...[
                        _sectionTitle('Deals this week', () {
                          deps.shop.setSort(ProductSort.priceLow);
                          deps.shell.select(ShopTab.shop);
                        }),
                        SliverToBoxAdapter(child: _productRow(home.deals)),
                      ],
                      if (browsing && home.fresh.isNotEmpty) ...[
                        _sectionTitle('New arrivals', () {
                          deps.shop.setSort(ProductSort.newest);
                          deps.shell.select(ShopTab.shop);
                        }),
                        SliverToBoxAdapter(child: _productRow(home.fresh)),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  home.query.isNotEmpty
                                      ? 'Search results'
                                      : home.category == 'All'
                                          ? 'Trending now'
                                          : home.category,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                              Text('${products.length} items',
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      if (products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                              child: Text('No shoes match that search.')),
                        )
                      else
                        _grid(products),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _locationCard(BuildContext context, Shop deps) {
    final location = deps.location;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .17),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => changeCustomerLocation(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR LOCATION',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              letterSpacing: .6),
                        ),
                        Text(
                          location.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (location.loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          InkWell(
            onTap: () => chooseBranch(context),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SHOPPING FROM',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              letterSpacing: .6),
                        ),
                        Text(
                          deps.branches.selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, Shop deps) {
    final top = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: AppDecor.header,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, top + 8, 18, 20),
        child: Column(
          children: [
            Row(
              children: [
                const BrandLogo(size: 62),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen())),
                  icon: Badge(
                    isLabelVisible: deps.notices.unread > 0,
                    backgroundColor: Colors.white,
                    textColor: AppColors.deepGreen,
                    label: Text('${deps.notices.unread}'),
                    child: const Icon(Icons.notifications_none,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _locationCard(context, deps),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: deps.home.setQuery,
              decoration: InputDecoration(
                hintText: 'Search shoes, styles, colours...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: deps.home.query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          deps.home.clearQuery();
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bannerPager(BuildContext context) {
    final deps = Shop.of(context);
    final banners = [
      _BannerData(
        kicker: 'STEP INTO',
        title: 'YOUR STYLE',
        subtitle: 'Fresh drops. Everyday comfort.',
        action: 'Shop sneakers',
        imageUrl: deps.catalog.findById('sf001')?.imageUrl ?? '',
        onTap: () => deps.home.setCategory('Sneakers'),
      ),
      _BannerData(
        kicker: 'FORMAL WEEK',
        title: 'LOOK SHARP',
        subtitle: 'Office pairs, ready for pickup.',
        action: 'Shop formal',
        imageUrl: deps.catalog.findById('sf009')?.imageUrl ?? '',
        onTap: () => deps.home.setCategory('Formal'),
      ),
    ];
    _bannerPages = banners.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 198,
            child: Listener(
              onPointerDown: (_) => _bannerTimer?.cancel(),
              onPointerUp: (_) => _startBannerTimer(),
              onPointerCancel: (_) => _startBannerTimer(),
              child: PageView.builder(
                controller: _banner,
                itemCount: banners.length,
                onPageChanged: (value) => setState(() => _bannerIndex = value),
                itemBuilder: (context, index) =>
                    _BannerCard(data: banners[index]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final active = index == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                width: active ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.green : AppColors.line,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, VoidCallback onViewAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 8, 10),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900))),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
      ),
    );
  }

  Widget _productRow(List<Product> products) {
    return SizedBox(
      height: 276,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => FadeSlideIn(
          key: ValueKey('row-${products[index].id}-$index'),
          index: index,
          child: SizedBox(
              width: 168, child: catalogCard(context, products[index])),
        ),
      ),
    );
  }

  Widget _grid(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.58,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => FadeSlideIn(
            key: ValueKey(products[index].id),
            index: index,
            child: catalogCard(context, products[index]),
          ),
          childCount: products.length,
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_outlined, 'Free over ₹4,999'),
      (Icons.replay, '7-day returns'),
      (Icons.storefront_outlined, 'Store pickup'),
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Icon(item.$1, size: 14, color: AppColors.deepGreen),
                const SizedBox(width: 6),
                Text(item.$2,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BannerData {
  const _BannerData({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.imageUrl,
    required this.onTap,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final String action;
  final String imageUrl;
  final VoidCallback onTap;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.data});

  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: data.onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF101510), Color(0xFF1C3A24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data.kicker,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800)),
                    Text(data.title,
                        style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(data.subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: data.onTap,
                      child: Text(data.action),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: data.imageUrl.isEmpty
                      ? const SizedBox.shrink()
                      : ProductImage(url: data.imageUrl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
