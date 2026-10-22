import 'dart:async';
import 'dart:math';

import '../entities/shop_models.dart';
import '../gateways/shop_gateways.dart';
import '../pricing/pricing.dart';
import '../repositories/shop_repositories.dart';
import '../validation/validators.dart';
import 'shop_results.dart';

export 'shop_results.dart';

class CatalogUseCases {
  CatalogUseCases(this._catalog, {this.reload, this.load});

  final CatalogRepository _catalog;
  final Future<List<Product>> Function()? reload;
  final Future<Product> Function(String id)? load;
  StreamSubscription<void>? _listing;

  Stream<List<Product>> watch() => _catalog.watch();

  void startListing({Duration every = const Duration(seconds: 10)}) {
    if (reload == null || _listing != null) return;
    _listing = Stream<void>.periodic(every).listen((_) {
      refresh().ignore();
    });
  }

  Future<void> refresh() async {
    final load = reload;
    if (load == null) return;
    _catalog.replaceAll(await load());
  }

  List<String> get categories =>
      const ['All', 'Sneakers', 'Sports', 'Casual', 'Formal', 'Sandals'];

  Product? findById(String id) => _catalog.findById(id);

  Future<Product?> open(String id) async {
    final fetch = load;
    if (fetch == null) return _catalog.findById(id);
    final product = await fetch(id);
    _catalog.upsert(product);
    return product;
  }

  List<Product> browse(
      {String query = '',
      String category = 'All',
      ProductSort sort = ProductSort.featured}) {
    final needle = query.trim().toLowerCase();
    final list = _catalog.products.where((product) {
      if (category != 'All' && product.category != category) return false;
      if (needle.isEmpty) return true;
      final haystack =
          '${product.name} ${product.category} ${product.description} ${product.colors.join(' ')}'
              .toLowerCase();
      return haystack.contains(needle);
    }).toList();
    list.sort((a, b) => _compare(a, b, sort));
    return list;
  }

  List<Product> deals() {
    final list = _catalog.products
        .where((product) => product.discountPercent >= 15)
        .toList();
    list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    return list;
  }

  List<Product> fresh() =>
      _catalog.products.where((product) => product.isNew).toList();

  List<Product> relatedTo(Product product, {int limit = 4}) {
    final sameCategory = <Product>[];
    final others = <Product>[];
    for (final candidate in _catalog.products) {
      if (candidate.id == product.id) continue;
      if (candidate.category == product.category) {
        sameCategory.add(candidate);
      } else {
        others.add(candidate);
      }
    }
    return [...sameCategory, ...others].take(limit).toList();
  }

  int _compare(Product a, Product b, ProductSort sort) {
    switch (sort) {
      case ProductSort.priceLow:
        return a.price.compareTo(b.price);
      case ProductSort.priceHigh:
        return b.price.compareTo(a.price);
      case ProductSort.rating:
        return b.rating.compareTo(a.rating);
      case ProductSort.newest:
        if (a.isNew != b.isNew) return a.isNew ? -1 : 1;
        return b.rating.compareTo(a.rating);
      case ProductSort.featured:
        return _featuredRank(b).compareTo(_featuredRank(a));
    }
  }

  int _featuredRank(Product product) {
    var rank = (product.rating * 10).round();
    if (product.badge != null) rank += 20;
    return rank;
  }
}

class CartUseCases implements CartGateway {
  CartUseCases(this._cart, this._catalog);

  final CartRepository _cart;
  final CatalogRepository _catalog;

  @override
  List<CartItem> get items => _cart.items;
  @override
  String? get couponCode => _cart.couponCode;
  @override
  int get count => _cart.items.fold(0, (sum, item) => sum + item.quantity);
  @override
  double get subtotal =>
      _cart.items.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  PriceQuote quote({required bool pickup}) {
    return Pricing.calculate(
        subtotal: subtotal, couponCode: couponCode, pickup: pickup);
  }

  @override
  Future<AddToCartResult> add(Product product,
      {required int size, required String color, int quantity = 1}) async {
    if (product.stock <= 0) {
      return const AddToCartResult(
          added: false, message: 'This pair is out of stock.');
    }
    if (product.colors.isNotEmpty && !product.colors.contains(color)) {
      return AddToCartResult(
          added: false,
          message: '${product.name} is not available in that colour.');
    }
    if (product.sizes.isNotEmpty && !product.sizes.contains(size)) {
      return AddToCartResult(
          added: false,
          message: '${product.name} is not available in that size.');
    }
    final id = '${product.id}|$size|$color';
    CartItem? existing;
    for (final item in _cart.items) {
      if (item.id == id) existing = item;
    }
    final currentQty = existing?.quantity ?? 0;
    final cap = product.stock < 5 ? product.stock : 5;
    final requested = currentQty + quantity;
    final next = requested > cap ? cap : requested;
    if (next == currentQty) {
      return const AddToCartResult(
          added: false,
          message: 'You already have the maximum available for this pair.');
    }
    _cart.upsert(
      CartItem(
        id: id,
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        unitPrice: product.price,
        color: color,
        size: size,
        quantity: next,
      ),
    );
    final message = requested > cap
        ? 'Only $cap of this pair can be added. Your cart was updated.'
        : '${product.name} added to your cart.';
    return AddToCartResult(added: true, message: message);
  }

  @override
  Future<void> setQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      _cart.remove(id);
      return;
    }
    CartItem? existing;
    for (final item in _cart.items) {
      if (item.id == id) existing = item;
    }
    if (existing == null) return;
    final product = _catalog.findById(existing.productId);
    final cap = product == null ? 5 : (product.stock < 5 ? product.stock : 5);
    _cart.upsert(existing.copyWith(quantity: quantity > cap ? cap : quantity));
  }

  @override
  Future<void> remove(String id) async => _cart.remove(id);

  @override
  Future<CouponAttempt> applyCoupon(String code, {required bool pickup}) async {
    final attempt =
        Pricing.evaluate(subtotal: subtotal, rawCode: code, pickup: pickup);
    if (attempt.accepted) _cart.setCoupon(attempt.quote.couponCode);
    return attempt;
  }

  @override
  Future<void> clearCoupon() async => _cart.setCoupon(null);

  @override
  Future<void> clear() async => _cart.clear();

  @override
  Future<void> reload() async {}
}

class WishlistUseCases implements WishlistGateway {
  WishlistUseCases(this._wishlist, this._catalog);

  final WishlistRepository _wishlist;
  final CatalogRepository _catalog;

  @override
  List<Product> get products {
    final result = <Product>[];
    for (final id in _wishlist.ids) {
      final product = _catalog.findById(id);
      if (product != null) result.add(product);
    }
    return result;
  }

  @override
  bool contains(String id) => _wishlist.contains(id);

  @override
  Future<void> toggle(String id) async => _wishlist.toggle(id);
}

class OrderUseCases implements OrderGateway {
  OrderUseCases(this._orders, this._cart, this._catalog, {NoticeRepository? notices})
      : _notices = notices;

  final OrderRepository _orders;
  final CartUseCases _cart;
  final CatalogRepository _catalog;
  final NoticeRepository? _notices;

  @override
  List<ShopOrder> get orders => _orders.orders;

  @override
  ShopOrder? byId(String id) => _orders.find(id);

  @override
  Future<PriceQuote> preview({required bool pickup}) async {
    return _cart.quote(pickup: pickup);
  }

  @override
  Future<ShopOrder> place({
    required List<CartItem> items,
    required PriceQuote quote,
    required String fulfilment,
    required String paymentMethod,
    required String contactName,
    required String contactPhone,
    required String destination,
    String? paymentReference,
    String? branchId,
  }) async {
    final order = ShopOrder(
      id: _orders.nextId(),
      placedAt: DateTime.now(),
      lines: [
        for (final item in items)
          OrderLine(
            productId: item.productId,
            name: item.name,
            imageUrl: item.imageUrl,
            unitPrice: item.unitPrice,
            color: item.color,
            size: item.size,
            quantity: item.quantity,
          ),
      ],
      subtotal: quote.subtotal,
      discount: quote.discount,
      deliveryFee: quote.deliveryFee,
      total: quote.total,
      fulfilment: fulfilment,
      paymentMethod: paymentMethod,
      status: OrderStatus.confirmed,
      destination: destination,
      contactName: contactName,
      contactPhone: contactPhone,
      couponCode: quote.couponCode,
      paymentReference: paymentReference,
    );
    _orders.add(order);
    _notices?.push(_orderNotice(order));
    await _cart.clear();
    return order;
  }

  @override
  Future<bool> cancel(String id) async {
    final order = _orders.find(id);
    if (order == null || !order.canCancel) return false;
    final cancelled = order.copyWith(status: OrderStatus.cancelled);
    _orders.update(cancelled);
    _notices?.push(_orderNotice(cancelled));
    return true;
  }

  @override
  Future<int> reorder(ShopOrder order) async {
    var units = 0;
    for (final line in order.lines) {
      final product = _catalog.findById(line.productId);
      if (product == null) continue;
      final result = await _cart.add(product,
          size: line.size, color: line.color, quantity: line.quantity);
      if (result.added) units += line.quantity;
    }
    return units;
  }
}

class _PendingOtp {
  _PendingOtp(
      {required this.phone, required this.code, required this.expiresAt});

  final String phone;
  final String code;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AccountUseCases implements AccountGateway {
  AccountUseCases(this._account);

  final AccountRepository _account;
  final Random _random = Random();
  _PendingOtp? _otp;

  @override
  UserAccount? get user => _account.user;
  @override
  List<Address> get addresses => _account.addresses;

  @override
  Address? get defaultAddress {
    for (final address in _account.addresses) {
      if (address.isDefault) return address;
    }
    if (_account.addresses.isEmpty) return null;
    return _account.addresses.first;
  }

  @override
  Future<OtpRequest> requestOtp(String phone) async {
    final digits = Validators.digits(phone);
    if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) {
      return const OtpRequest(error: 'Enter a 10-digit mobile number.');
    }
    final code = (_random.nextInt(900000) + 100000).toString();
    _otp = _PendingOtp(
      phone: digits,
      code: code,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    return OtpRequest(
      code: code,
      registered: _account.findByPhone(digits) != null,
    );
  }

  @override
  Future<OtpSignIn> verifyOtp({required String phone, required String code}) async {
    final pending = _matchOtp(phone, code);
    if (pending is String) return OtpSignIn(error: pending);
    final account = _account.findByPhone(Validators.digits(phone));
    if (account == null) return const OtpSignIn(needsProfile: true);
    _otp = null;
    _openSession(account);
    return const OtpSignIn(signedIn: true);
  }

  @override
  Future<String?> registerWithOtp({
    required String name,
    required String email,
    required String phone,
    required String code,
  }) async {
    final pending = _matchOtp(phone, code);
    if (pending is String) return pending;
    if (_account.findByPhone(phone) != null) {
      return 'An account with this mobile number already exists. Sign in instead.';
    }
    final error = Validators.account(name: name, email: email, phone: phone);
    if (error != null) return error;
    if (_account.hasEmail(email)) {
      return 'An account with this email already exists. Sign in instead.';
    }
    final account = UserAccount(
      name: name.trim(),
      email: email.trim(),
      phone: Validators.digits(phone),
    );
    _account.saveCredential(
      account,
      'otp-${DateTime.now().microsecondsSinceEpoch}',
    );
    _otp = null;
    _openSession(account);
    return null;
  }

  String? _matchOtp(String phone, String code) {
    final digits = Validators.digits(phone);
    final pending = _otp;
    if (pending == null || pending.phone != digits) {
      return 'Request a code for this mobile number first.';
    }
    if (pending.isExpired) return 'That code has expired. Request a new one.';
    if (pending.code != Validators.digits(code)) {
      return 'That code does not match.';
    }
    return null;
  }

  @override
  Future<String?> signInWithPassword(
      {required String email, required String password}) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return 'Enter a valid email.';
    }
    if (password.trim().length < 4) {
      return 'Use a password of at least 4 characters.';
    }
    if (!_account.hasEmail(trimmedEmail)) {
      return 'No account uses that email. Create one to continue.';
    }
    final account = _account.authenticate(trimmedEmail, password.trim());
    if (account == null) return 'That password does not match.';
    _openSession(account);
    return null;
  }

  @override
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) return 'Passwords do not match.';
    final error = Validators.account(
        name: name,
        email: email,
        phone: phone,
        password: password,
        checkPassword: true);
    if (error != null) return error;
    if (_account.hasEmail(email)) {
      return 'An account with this email already exists. Sign in instead.';
    }
    if (_account.findByPhone(phone) != null) {
      return 'An account with this mobile number already exists. Sign in instead.';
    }
    final account = UserAccount(
        name: name.trim(),
        email: email.trim(),
        phone: Validators.digits(phone));
    _account.saveCredential(account, password.trim());
    _openSession(account);
    return null;
  }

  final Map<String, String> _resetCodes = {};

  @override
  Future<OtpRequest> requestPasswordReset(String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return const OtpRequest(error: 'Enter a valid email.');
    }
    if (!_account.hasEmail(trimmedEmail)) {
      return const OtpRequest(error: 'No account uses that email.');
    }
    final code = (_random.nextInt(900000) + 100000).toString();
    _resetCodes[trimmedEmail] = code;
    return OtpRequest(code: code);
  }

  @override
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (!trimmedEmail.contains('@') || !trimmedEmail.contains('.')) {
      return 'Enter a valid email.';
    }
    if (password != confirmPassword) return 'Passwords do not match.';
    if (password.trim().length < 4) {
      return 'Use a password of at least 4 characters.';
    }
    final pending = _resetCodes[trimmedEmail];
    if (pending == null) return 'Request a reset code for this email first.';
    if (pending != code.trim()) return 'That code does not match.';
    if (!_account.changePassword(trimmedEmail, password.trim())) {
      return 'No account uses that email.';
    }
    _resetCodes.remove(trimmedEmail);
    return null;
  }

  @override
  Future<void> signOut() async => _account.signOut();

  @override
  Future<String?> updateProfile(
      {required String name, required String email, required String phone}) async {
    final error = Validators.account(name: name, email: email, phone: phone);
    if (error != null) return error;
    final current = _account.user;
    final nextEmail = email.trim().toLowerCase();
    if (current != null &&
        current.email.trim().toLowerCase() != nextEmail &&
        _account.hasEmail(email)) {
      return 'Another account already uses that email.';
    }
    final nextPhone = Validators.digits(phone);
    if (current != null &&
        current.phone != nextPhone &&
        _account.findByPhone(nextPhone) != null) {
      return 'Another account already uses that mobile number.';
    }
    _account.update(UserAccount(
        name: name.trim(),
        email: email.trim(),
        phone: Validators.digits(phone)));
    return null;
  }

  void _openSession(UserAccount account) {
    _account.signIn(account);
  }

  @override
  Future<String?> saveAddress({
    String? id,
    required String label,
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) async {
    final error = Validators.address(
        label: label,
        name: name,
        phone: phone,
        line: line,
        city: city,
        pincode: pincode);
    if (error != null) return error;
    var isDefault = _account.addresses.isEmpty;
    if (id != null) {
      for (final address in _account.addresses) {
        if (address.id == id) isDefault = address.isDefault;
      }
    }
    _account.saveAddress(
      Address(
        id: id ?? 'addr-${DateTime.now().millisecondsSinceEpoch}',
        label: label.trim(),
        name: name.trim(),
        phone: Validators.digits(phone),
        line: line.trim(),
        city: city.trim(),
        pincode: Validators.digits(pincode),
        isDefault: isDefault,
      ),
    );
    return null;
  }

  @override
  Future<void> deleteAddress(String id) async => _account.deleteAddress(id);

  @override
  Future<void> setDefault(String id) async => _account.setDefault(id);
}

class BranchUseCases {
  BranchUseCases(this._branches);

  final BranchRepository _branches;

  List<Branch> get branches => _branches.branches;
  Branch get selected => _branches.selected;

  void select(String id) => _branches.select(id);
}

class NoticeUseCases implements NoticeGateway {
  NoticeUseCases(this._notices);

  final NoticeRepository _notices;

  @override
  List<ShopNotice> get notices => _notices.notices;
  @override
  int get unread => _notices.notices.where((notice) => !notice.read).length;

  @override
  Future<void> markAllRead() async => _notices.markAllRead();

  @override
  Future<void> markRead(String id) async => _notices.markRead(id);

  @override
  Future<void> dismiss(String id) async => _notices.dismiss(id);

  @override
  Future<void> refresh() async {}
}

ShopNotice _orderNotice(ShopOrder order) {
  final id = order.id;
  final String title;
  final String body;
  switch (order.status) {
    case OrderStatus.confirmed:
      title = 'Order $id is confirmed';
      body = 'We have received your order. The branch will start packing it.';
    case OrderStatus.preparing:
      title = 'Order $id is being prepared';
      body = 'The branch is packing your shoes.';
    case OrderStatus.onTheWay:
      title = 'Order $id is on the way';
      body = 'Your pair has left the branch.';
    case OrderStatus.completed:
      title = 'Order $id is complete';
      body = 'Thanks for shopping at Shoe Factory.';
    case OrderStatus.cancelled:
      title = 'Order $id was cancelled';
      body = 'The order is cancelled. Any reserved stock is back on the shelf.';
  }
  return ShopNotice(
    id: 'order-$id-${order.status.name}-${DateTime.now().microsecondsSinceEpoch}',
    title: title,
    body: body,
    timeLabel: 'Just now',
    kind: 'order',
    targetId: id,
  );
}
