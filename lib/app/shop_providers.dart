import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../domain/gateways/shop_gateways.dart';
import '../domain/usecases/shop_use_cases.dart';
import '../presentation/viewmodels/shop_view_models.dart';
import 'dependencies.dart';

class ShopProviders extends StatelessWidget {
  const ShopProviders({super.key, required this.dependencies, required this.child});

  final AppDependencies dependencies;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final deps = dependencies;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShellViewModel>.value(value: deps.shell),
        ChangeNotifierProvider<HomeCatalogViewModel>.value(value: deps.home),
        ChangeNotifierProvider<ShopCatalogViewModel>.value(value: deps.shop),
        ChangeNotifierProvider<CartViewModel>.value(value: deps.cart),
        ChangeNotifierProvider<WishlistViewModel>.value(value: deps.wishlist),
        ChangeNotifierProvider<OrdersViewModel>.value(value: deps.orders),
        ChangeNotifierProvider<SessionViewModel>.value(value: deps.session),
        ChangeNotifierProvider<BranchViewModel>.value(value: deps.branches),
        ChangeNotifierProvider<LocationViewModel>.value(value: deps.location),
        ChangeNotifierProvider<NoticesViewModel>.value(value: deps.notices),
        Provider<CatalogUseCases>.value(value: deps.catalog),
        Provider<AccountGateway>.value(value: deps.account),
        Provider<BranchUseCases>.value(value: deps.branchUseCases),
        Provider<CartGateway>.value(value: deps.cartUseCases),
        Provider<OrderGateway>.value(value: deps.orderUseCases),
      ],
      child: child,
    );
  }
}
