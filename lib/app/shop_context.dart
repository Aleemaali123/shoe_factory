import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../domain/gateways/shop_gateways.dart';
import '../domain/usecases/shop_use_cases.dart';
import '../presentation/viewmodels/shop_view_models.dart';

class Shop {
  Shop._(this._context);

  final BuildContext _context;

  static Shop of(BuildContext context) => Shop._(context);

  ShellViewModel get shell => _context.read<ShellViewModel>();
  HomeCatalogViewModel get home => _context.read<HomeCatalogViewModel>();
  ShopCatalogViewModel get shop => _context.read<ShopCatalogViewModel>();
  CartViewModel get cart => _context.read<CartViewModel>();
  WishlistViewModel get wishlist => _context.read<WishlistViewModel>();
  OrdersViewModel get orders => _context.read<OrdersViewModel>();
  SessionViewModel get session => _context.read<SessionViewModel>();
  BranchViewModel get branches => _context.read<BranchViewModel>();
  LocationViewModel get location => _context.read<LocationViewModel>();
  NoticesViewModel get notices => _context.read<NoticesViewModel>();
  CatalogUseCases get catalog => _context.read<CatalogUseCases>();
  AccountGateway get account => _context.read<AccountGateway>();
  BranchUseCases get branchUseCases => _context.read<BranchUseCases>();
  CartGateway get cartUseCases => _context.read<CartGateway>();
  OrderGateway get orderUseCases => _context.read<OrderGateway>();
}
