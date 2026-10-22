import '../../core/network/api_client.dart';
import '../../domain/entities/shop_models.dart';
import '../../domain/gateways/shop_gateways.dart';
import '../../domain/pricing/pricing.dart';
import '../../domain/repositories/shop_repositories.dart';
import '../../domain/usecases/shop_results.dart';
import 'auth_api.dart';
import 'checkout_api.dart';
import 'profile_api.dart';
import 'shop_mapper.dart';

class ShopSnapshot {
  ShopSnapshot({
    required this.products,
    required this.branches,
    required this.notices,
    required this.cart,
    required this.couponCode,
    required this.wishlistIds,
    required this.orders,
    required this.user,
    required this.addresses,
  });

  final List<Product> products;
  final List<Branch> branches;
  final List<ShopNotice> notices;
  final List<CartItem> cart;
  final String? couponCode;
  final List<String> wishlistIds;
  final List<ShopOrder> orders;
  final UserAccount? user;
  final List<Address> addresses;

  factory ShopSnapshot.fromJson(Map<String, dynamic> json) {
    final cart = asMap(json['cart']);
    final user = json['user'];
    return ShopSnapshot(
      products: [
        for (final item in json['products'] as List) productFromJson(asMap(item)),
      ],
      branches: [
        for (final item in json['branches'] as List) branchFromJson(asMap(item)),
      ],
      notices: [
        for (final item in json['notices'] as List) noticeFromJson(asMap(item)),
      ],
      cart: [
        for (final item in cart['items'] as List) cartItemFromJson(asMap(item)),
      ],
      couponCode: cart['couponCode'] as String?,
      wishlistIds: [
        for (final id in json['wishlist'] as List) id as String,
      ],
      orders: [
        for (final item in json['orders'] as List) orderFromJson(asMap(item)),
      ],
      user: user == null ? null : userFromJson(asMap(user)),
      addresses: [
        for (final item in json['addresses'] as List? ?? const [])
          addressFromJson(asMap(item)),
      ],
    );
  }
}

class RemoteShopCache {
  RemoteShopCache.from(ShopSnapshot snapshot)
      : cart = List.of(snapshot.cart),
        couponCode = snapshot.couponCode,
        wishlistIds = List.of(snapshot.wishlistIds),
        orders = List.of(snapshot.orders),
        notices = List.of(snapshot.notices),
        user = snapshot.user,
        addresses = List.of(snapshot.addresses);

  List<CartItem> cart;
  String? couponCode;
  List<String> wishlistIds;
  List<ShopOrder> orders;
  List<ShopNotice> notices;
  UserAccount? user;
  List<Address> addresses;

  void applyCart(Map<String, dynamic> json) {
    cart = [for (final item in json['items'] as List) cartItemFromJson(asMap(item))];
    couponCode = json['couponCode'] as String?;
  }

  void applyProfile(Map<String, dynamic> json) {
    final rawUser = json['user'];
    user = rawUser == null ? null : userFromJson(asMap(rawUser));
    addresses = [
      for (final item in json['addresses'] as List? ?? const [])
        addressFromJson(asMap(item)),
    ];
  }

  void applyAddresses(List<dynamic> json) {
    addresses = [for (final item in json) addressFromJson(asMap(item))];
  }

  void replaceOrder(ShopOrder order) {
    final index = orders.indexWhere((item) => item.id == order.id);
    if (index >= 0) orders[index] = order;
  }
}

class ShopApi {
  ShopApi({required String baseUrl}) : _client = ApiClient(baseUrl: baseUrl);

  final ApiClient _client;

  Future<ShopSnapshot> openSession() async {
    final data = asMap(await _client.post('/api/session'));
    _client.token = data['token'] as String;
    return ShopSnapshot.fromJson(data);
  }

  Future<dynamic> get(String path) => _client.get(path);

  Future<List<Product>> products() async {
    final data = await _client.get('/api/catalog/products');
    return [
      for (final item in data as List) productFromJson(asMap(item)),
    ];
  }

  Future<Product> product(String id) async {
    final data = await _client.get(
        '/api/catalog/products/${Uri.encodeComponent(id)}');
    return productFromJson(asMap(data));
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _client.post(path, body);

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _client.patch(path, body);

  Future<dynamic> delete(String path) => _client.delete(path);
}

class ApiCartGateway implements CartGateway {
  ApiCartGateway(this._api, this._cache);

  final ShopApi _api;
  final RemoteShopCache _cache;

  @override
  List<CartItem> get items => List.unmodifiable(_cache.cart);

  @override
  String? get couponCode => _cache.couponCode;

  @override
  int get count => _cache.cart.fold(0, (sum, item) => sum + item.quantity);

  @override
  double get subtotal =>
      _cache.cart.fold(0, (sum, item) => sum + item.lineTotal);

  @override
  PriceQuote quote({required bool pickup}) {
    return Pricing.calculate(
        subtotal: subtotal, couponCode: couponCode, pickup: pickup);
  }

  @override
  Future<AddToCartResult> add(Product product,
      {required int size, required String color, int quantity = 1}) async {
    final data = asMap(await _api.post('/api/cart/items', {
      'productId': product.id,
      'size': size,
      'color': color,
      'quantity': quantity,
    }));
    _cache.applyCart(asMap(data['cart']));
    return AddToCartResult(
        added: data['added'] as bool, message: data['message'] as String);
  }

  @override
  Future<void> setQuantity(String id, int quantity) async {
    final data = asMap(await _api.patch(
        '/api/cart/items/${Uri.encodeComponent(id)}',
        {'quantity': quantity}));
    _cache.applyCart(data);
  }

  @override
  Future<void> remove(String id) async {
    final data =
        asMap(await _api.delete('/api/cart/items/${Uri.encodeComponent(id)}'));
    _cache.applyCart(data);
  }

  @override
  Future<CouponAttempt> applyCoupon(String code, {required bool pickup}) async {
    final data = asMap(await _api.post('/api/cart/coupon', {
      'code': code,
      'pickup': pickup,
    }));
    _cache.applyCart(asMap(data['cart']));
    final quote = asMap(data['quote']);
    return CouponAttempt(
      accepted: data['accepted'] as bool,
      message: data['message'] as String,
      quote: PriceQuote(
        subtotal: (quote['subtotal'] as num).toDouble(),
        discount: (quote['discount'] as num).toDouble(),
        deliveryFee: (quote['deliveryFee'] as num).toDouble(),
        total: (quote['total'] as num).toDouble(),
        couponCode: quote['couponCode'] as String?,
        couponLabel: quote['couponLabel'] as String?,
      ),
    );
  }

  @override
  Future<void> clearCoupon() async {
    _cache.applyCart(asMap(await _api.delete('/api/cart/coupon')));
  }

  @override
  Future<void> clear() async {
    _cache.cart = [];
    _cache.couponCode = null;
  }
}

class ApiWishlistGateway implements WishlistGateway {
  ApiWishlistGateway(this._api, this._cache, this._catalog);

  final ShopApi _api;
  final RemoteShopCache _cache;
  final CatalogRepository _catalog;

  @override
  List<Product> get products {
    final result = <Product>[];
    for (final id in _cache.wishlistIds) {
      final product = _catalog.findById(id);
      if (product != null) result.add(product);
    }
    return result;
  }

  @override
  bool contains(String id) => _cache.wishlistIds.contains(id);

  @override
  Future<void> toggle(String id) async {
    final data = await _api.post('/api/wishlist/$id');
    _cache.wishlistIds = [for (final item in data as List) item as String];
  }
}

class ApiOrderGateway implements OrderGateway {
  ApiOrderGateway(ShopApi api, this._cache)
      : _api = api,
        _checkout = CheckoutApi(api);

  final ShopApi _api;
  final CheckoutApi _checkout;
  final RemoteShopCache _cache;

  @override
  Future<PriceQuote> preview({required bool pickup}) {
    return _checkout.quote(pickup: pickup);
  }

  @override
  List<ShopOrder> get orders => List.unmodifiable(_cache.orders);

  @override
  ShopOrder? byId(String id) {
    for (final order in _cache.orders) {
      if (order.id == id) return order;
    }
    return null;
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
  }) async {
    final order = await _checkout.place(
      fulfilment: fulfilment,
      paymentMethod: paymentMethod,
      contactName: contactName,
      contactPhone: contactPhone,
      destination: destination,
      paymentReference: paymentReference,
    );
    _cache.orders.insert(0, order);
    _cache.cart = [];
    _cache.couponCode = null;
    return order;
  }

  @override
  Future<bool> cancel(String id) async {
    final data = asMap(await _api.post('/api/orders/$id/cancel'));
    _cache.replaceOrder(orderFromJson(asMap(data['order'])));
    return data['cancelled'] as bool;
  }

  @override
  Future<int> reorder(ShopOrder order) async {
    final data = asMap(await _api.post('/api/orders/${order.id}/reorder'));
    _cache.applyCart(asMap(data['cart']));
    return (data['units'] as num).toInt();
  }
}

class ApiAccountGateway implements AccountGateway {
  ApiAccountGateway(ShopApi api, this._cache)
      : _auth = AuthApi(api),
        _profile = ProfileApi(api);

  final AuthApi _auth;
  final ProfileApi _profile;
  final RemoteShopCache _cache;

  @override
  UserAccount? get user => _cache.user;

  @override
  List<Address> get addresses => List.unmodifiable(_cache.addresses);

  @override
  Address? get defaultAddress {
    for (final address in _cache.addresses) {
      if (address.isDefault) return address;
    }
    if (_cache.addresses.isEmpty) return null;
    return _cache.addresses.first;
  }

  @override
  Future<OtpRequest> requestOtp(String phone) async {
    try {
      final data = await _auth.requestOtp(phone);
      return OtpRequest(
        code: data['code'] as String?,
        registered: data['registered'] as bool? ?? false,
      );
    } on ApiException catch (error) {
      return OtpRequest(error: error.message);
    }
  }

  @override
  Future<OtpSignIn> verifyOtp(
      {required String phone, required String code}) async {
    try {
      final data = await _auth.verifyOtp(phone: phone, code: code);
      if (data['needsProfile'] == true) return const OtpSignIn(needsProfile: true);
      _cache.applyProfile(data);
      return const OtpSignIn(signedIn: true);
    } on ApiException catch (error) {
      return OtpSignIn(error: error.message);
    }
  }

  @override
  Future<String?> registerWithOtp({
    required String name,
    required String email,
    required String phone,
    required String code,
  }) async {
    try {
      _cache.applyProfile(await _auth.registerWithOtp(
        name: name,
        email: email,
        phone: phone,
        code: code,
      ));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> signInWithPassword(
      {required String email, required String password}) async {
    try {
      _cache.applyProfile(await _auth.login(email: email, password: password));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      _cache.applyProfile(await _auth.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword,
      ));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await _auth.resetPassword(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.logout();
    _cache.user = null;
    _cache.addresses = [];
  }

  @override
  Future<String?> updateProfile(
      {required String name, required String email, required String phone}) async {
    try {
      _cache.applyProfile(await _profile.update(
        name: name,
        email: email,
        phone: phone,
      ));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
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
    try {
      _cache.applyAddresses(await _profile.saveAddress(
        id: id,
        label: label,
        name: name,
        phone: phone,
        line: line,
        city: city,
        pincode: pincode,
      ));
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    _cache.applyAddresses(await _profile.deleteAddress(id));
  }

  @override
  Future<void> setDefault(String id) async {
    _cache.applyAddresses(await _profile.setDefault(id));
  }
}

class ApiNoticeGateway implements NoticeGateway {
  ApiNoticeGateway(this._api, this._cache);

  final ShopApi _api;
  final RemoteShopCache _cache;

  @override
  List<ShopNotice> get notices => List.unmodifiable(_cache.notices);

  @override
  int get unread => _cache.notices.where((notice) => !notice.read).length;

  @override
  Future<void> markAllRead() async {
    final data = await _api.post('/api/notices/read');
    _cache.notices = [for (final item in data as List) noticeFromJson(asMap(item))];
  }
}
