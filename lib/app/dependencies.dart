import '../core/location/device_location.dart';
import '../core/network/api_config.dart';
import '../data/catalog/demo_catalog.dart';
import '../data/remote/remote_shop.dart';
import '../data/repositories/memory_shop.dart';
import '../domain/gateways/shop_gateways.dart';
import '../domain/usecases/shop_use_cases.dart';
import '../presentation/viewmodels/shop_view_models.dart';

class AppDependencies {
  AppDependencies._({
    required this.shell,
    required this.home,
    required this.shop,
    required this.cart,
    required this.wishlist,
    required this.orders,
    required this.session,
    required this.branches,
    required this.location,
    required this.notices,
    required this.catalog,
    required this.account,
    required this.branchUseCases,
    required this.cartUseCases,
    required this.orderUseCases,
  });

  factory AppDependencies.create({DeviceLocation? deviceLocation}) {
    final catalogRepo = MemoryCatalogRepository(demoProducts);
    final cartRepo = MemoryCartRepository();
    final wishlistRepo = MemoryWishlistRepository();
    final orderRepo = MemoryOrderRepository(buildSeedOrders());
    final accountRepo = MemoryAccountRepository();
    final branchRepo = MemoryBranchRepository(demoBranches);
    final noticeRepo = MemoryNoticeRepository(demoNotices);

    final catalog = CatalogUseCases(catalogRepo);
    final cart = CartUseCases(cartRepo, catalogRepo);
    final wishlist = WishlistUseCases(wishlistRepo, catalogRepo);
    final orders = OrderUseCases(orderRepo, cart, catalogRepo);
    final account = AccountUseCases(accountRepo);
    final branchUseCases = BranchUseCases(branchRepo);
    final notices = NoticeUseCases(noticeRepo);

    return AppDependencies._(
      shell: ShellViewModel(),
      home: HomeCatalogViewModel(catalog),
      shop: ShopCatalogViewModel(catalog),
      cart: CartViewModel(cart),
      wishlist: WishlistViewModel(wishlist, catalog: catalog.watch()),
      orders: OrdersViewModel(orders),
      session: SessionViewModel(account),
      branches: BranchViewModel(branchUseCases),
      location: LocationViewModel(
          deviceLocation ?? const GeolocatorDeviceLocation()),
      notices: NoticesViewModel(notices),
      catalog: catalog,
      account: account,
      branchUseCases: branchUseCases,
      cartUseCases: cart,
      orderUseCases: orders,
    );
  }

  final ShellViewModel shell;
  final HomeCatalogViewModel home;
  final ShopCatalogViewModel shop;
  final CartViewModel cart;
  final WishlistViewModel wishlist;
  final OrdersViewModel orders;
  final SessionViewModel session;
  final BranchViewModel branches;
  final LocationViewModel location;
  final NoticesViewModel notices;
  final CatalogUseCases catalog;
  final AccountGateway account;
  final BranchUseCases branchUseCases;
  final CartGateway cartUseCases;
  final OrderGateway orderUseCases;

  static Future<AppDependencies> connect({
    String? baseUrl,
    DeviceLocation? deviceLocation,
  }) async {
    final api = ShopApi(baseUrl: baseUrl ?? defaultApiBaseUrl());
    final snapshot = await api.openSession();
    final cache = RemoteShopCache.from(snapshot);
    final catalogRepo = MemoryCatalogRepository(snapshot.products);
    final branchRepo = MemoryBranchRepository(snapshot.branches);
    final catalog = CatalogUseCases(
      catalogRepo,
      reload: api.products,
      load: api.product,
    );
    catalog.startListing();
    final cart = ApiCartGateway(api, cache);
    final wishlist = ApiWishlistGateway(api, cache, catalogRepo);
    final orders = ApiOrderGateway(api, cache);
    final account = ApiAccountGateway(api, cache);
    final notices = ApiNoticeGateway(api, cache);
    final branchUseCases = BranchUseCases(branchRepo);
    return AppDependencies._(
      shell: ShellViewModel(),
      home: HomeCatalogViewModel(catalog),
      shop: ShopCatalogViewModel(catalog),
      cart: CartViewModel(cart),
      wishlist: WishlistViewModel(wishlist, catalog: catalog.watch()),
      orders: OrdersViewModel(orders),
      session: SessionViewModel(account),
      branches: BranchViewModel(branchUseCases),
      location: LocationViewModel(
          deviceLocation ?? const GeolocatorDeviceLocation()),
      notices: NoticesViewModel(notices),
      catalog: catalog,
      account: account,
      branchUseCases: branchUseCases,
      cartUseCases: cart,
      orderUseCases: orders,
    );
  }
}
