import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/location/device_location.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_store.dart';
import '../../domain/entities/shop_models.dart';
import '../../domain/gateways/shop_gateways.dart';
import '../../domain/pricing/pricing.dart';
import '../../domain/usecases/shop_use_cases.dart';

class ShopTab {
  static const home = 0;
  static const shop = 1;
  static const cart = 2;
  static const orders = 3;
  static const profile = 4;
}

class ShellViewModel extends ChangeNotifier {
  int index = ShopTab.home;

  void select(int value) {
    if (value == index) return;
    index = value;
    notifyListeners();
  }
}

class HomeCatalogViewModel extends CatalogViewModel {
  HomeCatalogViewModel(super.catalog);
}

class ShopCatalogViewModel extends CatalogViewModel {
  ShopCatalogViewModel(super.catalog);
}

class BranchViewModel extends ChangeNotifier {
  BranchViewModel(this._branches);

  final BranchUseCases _branches;

  List<Branch> get branches => _branches.branches;
  Branch get selected => _branches.selected;

  void select(String id) {
    _branches.select(id);
    SessionStore.saveBranch(id);
    notifyListeners();
  }

  void sync() => notifyListeners();
}

class LocationViewModel extends ChangeNotifier {
  LocationViewModel(this._device);

  final DeviceLocation _device;

  CustomerPlace? place;
  bool loading = false;
  String? error;
  bool canOpenSettings = false;
  bool _started = false;

  String get label {
    final current = place;
    if (current != null && current.label.isNotEmpty) return current.label;
    return loading ? 'Finding your location…' : 'Set your location';
  }

  Future<void> ensureDetected() {
    if (_started) return Future<void>.value();
    _started = true;
    return detect();
  }

  Future<void> detect() async {
    loading = true;
    error = null;
    canOpenSettings = false;
    notifyListeners();
    try {
      place = await _device.current();
    } on LocationFailure catch (failure) {
      error = failure.message;
      canOpenSettings = failure.openSettings;
    } catch (_) {
      error = 'Could not read your location. Enter it manually.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setManual({required String area, required String city}) {
    place = CustomerPlace(area: area.trim(), city: city.trim());
    error = null;
    canOpenSettings = false;
    _started = true;
    notifyListeners();
  }

  Future<void> openSettings() => _device.openSettings();
}

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._account);

  final AccountGateway _account;

  UserAccount? get user => _account.user;
  bool get isSignedIn => user != null;
  List<Address> get addresses => _account.addresses;
  Address? get defaultAddress => _account.defaultAddress;

  Future<OtpRequest> requestOtp(String phone) => _account.requestOtp(phone);

  Future<OtpSignIn> verifyOtp({required String phone, required String code}) async {
    final result = await _account.verifyOtp(phone: phone, code: code);
    if (result.signedIn) notifyListeners();
    return result;
  }

  Future<String?> registerWithOtp({
    required String name,
    required String email,
    required String phone,
    required String code,
  }) async {
    final error = await _account.registerWithOtp(
        name: name, email: email, phone: phone, code: code);
    if (error == null) notifyListeners();
    return error;
  }

  Future<String?> signInWithPassword(
      {required String email, required String password}) async {
    final error =
        await _account.signInWithPassword(email: email, password: password);
    if (error == null) notifyListeners();
    return error;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final error = await _account.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPassword);
    if (error == null) notifyListeners();
    return error;
  }

  Future<OtpRequest> requestPasswordReset(String email) {
    return _account.requestPasswordReset(email);
  }

  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
    required String confirmPassword,
  }) {
    return _account.resetPassword(
      email: email,
      code: code,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  Future<void> signOut() async {
    await _account.signOut();
    notifyListeners();
  }

  Future<String?> updateProfile(
      {required String name, required String email, required String phone}) async {
    final error =
        await _account.updateProfile(name: name, email: email, phone: phone);
    if (error == null) notifyListeners();
    return error;
  }

  Future<String?> saveAddress({
    String? id,
    required String label,
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) async {
    final error = await _account.saveAddress(
        id: id,
        label: label,
        name: name,
        phone: phone,
        line: line,
        city: city,
        pincode: pincode);
    if (error == null) notifyListeners();
    return error;
  }

  Future<void> deleteAddress(String id) async {
    await _account.deleteAddress(id);
    notifyListeners();
  }

  Future<void> setDefaultAddress(String id) async {
    await _account.setDefault(id);
    notifyListeners();
  }

  void sync() => notifyListeners();
}

class CatalogViewModel extends ChangeNotifier {
  CatalogViewModel(this._catalog) {
    _products = _catalog.watch().listen((_) => notifyListeners());
  }

  final CatalogUseCases _catalog;
  late final StreamSubscription<List<Product>> _products;

  String query = '';
  String category = 'All';
  ProductSort sort = ProductSort.featured;

  @override
  void dispose() {
    _products.cancel();
    super.dispose();
  }

  List<Product> get products =>
      _catalog.browse(query: query, category: category, sort: sort);
  List<Product> get deals => _catalog.deals();
  List<Product> get fresh => _catalog.fresh();
  List<String> get categories => _catalog.categories;

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void clearQuery() {
    if (query.isEmpty) return;
    query = '';
    notifyListeners();
  }

  void setCategory(String value) {
    category = value;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    sort = value;
    notifyListeners();
  }
}

class CartViewModel extends ChangeNotifier {
  CartViewModel(this._cart);

  final CartGateway _cart;

  String? couponMessage;
  bool couponAccepted = false;

  List<CartItem> get items => _cart.items;
  int get count => _cart.count;
  bool get isEmpty => items.isEmpty;
  String? get couponCode => _cart.couponCode;

  PriceQuote quote({required bool pickup}) => _cart.quote(pickup: pickup);

  Future<AddToCartResult> add(Product product,
      {required int size, required String color, int quantity = 1}) async {
    try {
      final result = await _cart.add(product,
          size: size, color: color, quantity: quantity);
      notifyListeners();
      return result;
    } on ApiException catch (error) {
      return AddToCartResult(added: false, message: error.message);
    }
  }

  Future<void> setQuantity(String lineId, int quantity) async {
    try {
      await _cart.setQuantity(lineId, quantity);
      notifyListeners();
    } on ApiException catch (error) {
      couponMessage = error.message;
      couponAccepted = false;
      notifyListeners();
    }
  }

  Future<void> remove(String lineId) async {
    try {
      await _cart.remove(lineId);
      notifyListeners();
    } on ApiException catch (error) {
      couponMessage = error.message;
      couponAccepted = false;
      notifyListeners();
    }
  }

  Future<void> applyCoupon(String code, {required bool pickup}) async {
    try {
      final result = await _cart.applyCoupon(code, pickup: pickup);
      couponMessage = result.message;
      couponAccepted = result.accepted;
    } on ApiException catch (error) {
      couponMessage = error.message;
      couponAccepted = false;
    }
    notifyListeners();
  }

  Future<void> clearCoupon() async {
    try {
      await _cart.clearCoupon();
      couponMessage = 'Coupon removed.';
      couponAccepted = false;
    } on ApiException catch (error) {
      couponMessage = error.message;
      couponAccepted = false;
    }
    notifyListeners();
  }

  void sync() => notifyListeners();
}

class WishlistViewModel extends ChangeNotifier {
  WishlistViewModel(this._wishlist, {Stream<List<Product>>? catalog}) {
    if (catalog != null) {
      _catalog = catalog.listen((_) => notifyListeners());
    }
  }

  final WishlistGateway _wishlist;
  StreamSubscription<List<Product>>? _catalog;

  List<Product> get products => _wishlist.products;

  @override
  void dispose() {
    _catalog?.cancel();
    super.dispose();
  }

  int get count => products.length;

  bool contains(String id) => _wishlist.contains(id);

  Future<String?> toggle(String id) async {
    try {
      await _wishlist.toggle(id);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel(this._orders);

  final OrderGateway _orders;

  List<ShopOrder> get orders => _orders.orders;

  ShopOrder? byId(String id) => _orders.byId(id);

  Future<bool> cancel(String id) async {
    try {
      final changed = await _orders.cancel(id);
      if (changed) notifyListeners();
      return changed;
    } on ApiException {
      return false;
    }
  }

  Future<int> reorder(ShopOrder order) async {
    try {
      final units = await _orders.reorder(order);
      notifyListeners();
      return units;
    } on ApiException {
      return 0;
    }
  }

  void sync() => notifyListeners();
}

class NoticesViewModel extends ChangeNotifier {
  NoticesViewModel(this._notices);

  final NoticeGateway _notices;

  List<ShopNotice> get notices => _notices.notices;
  int get unread => _notices.unread;

  Future<void> markAllRead() async {
    if (unread == 0) return;
    await _notices.markAllRead();
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    ShopNotice? current;
    for (final notice in notices) {
      if (notice.id == id) current = notice;
    }
    if (current == null || current.read) return;
    await _notices.markRead(id);
    notifyListeners();
  }

  Future<void> dismiss(String id) async {
    try {
      await _notices.dismiss(id);
    } on ApiException {
      await _notices.refresh();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      await _notices.refresh();
    } on ApiException {
      return;
    }
    notifyListeners();
  }

  void sync() => notifyListeners();
}

class ProductDetailViewModel extends ChangeNotifier {
  ProductDetailViewModel({required this.productId, required CatalogUseCases catalog})
      : _catalog = catalog {
    load();
  }

  final String productId;
  final CatalogUseCases _catalog;

  Product? product;
  List<Product> related = const [];
  bool loading = true;
  String? error;
  int size = 8;
  String color = '';
  int quantity = 1;

  int get maxQty {
    final stock = product?.stock ?? 0;
    if (stock <= 0) return 0;
    return stock < 5 ? stock : 5;
  }

  double get lineTotal => (product?.price ?? 0) * quantity;
  bool get inStock => maxQty > 0;

  Future<void> load() async {
    if (product == null) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final next = await _catalog.open(productId);
      if (next == null) {
        product = null;
        related = const [];
        error = 'This pair is no longer listed.';
      } else {
        final firstOpen = product == null;
        product = next;
        related = _catalog.relatedTo(next);
        if (firstOpen) {
          size = next.sizes.contains(8)
              ? 8
              : (next.sizes.isEmpty ? 8 : next.sizes.first);
          color = next.colors.isEmpty ? '' : next.colors.first;
          quantity = next.stock > 0 ? 1 : 0;
        } else if (quantity > maxQty) {
          quantity = maxQty;
        }
      }
    } on ApiException catch (failure) {
      if (product == null) error = failure.message;
    } catch (_) {
      if (product == null) error = 'Could not load this product.';
    }
    loading = false;
    notifyListeners();
  }

  void selectSize(int value) {
    size = value;
    notifyListeners();
  }

  void selectColor(String value) {
    color = value;
    notifyListeners();
  }

  void setQuantity(int value) {
    if (!inStock) return;
    final next = value.clamp(1, maxQty);
    if (next == quantity) return;
    quantity = next;
    notifyListeners();
  }
}

class CheckoutContact {
  const CheckoutContact({
    required this.name,
    required this.phone,
    required this.destination,
    required this.items,
    required this.quote,
    this.line,
    this.city,
    this.pincode,
    this.saveAddress = false,
  });

  final String name;
  final String phone;
  final String destination;
  final List<CartItem> items;
  final PriceQuote quote;
  final String? line;
  final String? city;
  final String? pincode;
  final bool saveAddress;
}

class CheckoutViewModel extends ChangeNotifier {
  CheckoutViewModel({
    required AccountGateway account,
    required BranchUseCases branches,
    required CartGateway cart,
    required OrderGateway orders,
  })  : _account = account,
        _branches = branches,
        _cart = cart,
        _orders = orders {
    final existing = _account.defaultAddress;
    if (existing != null) selectedAddressId = existing.id;
    pickupBranchId = _branches.selected.id;
    name = _account.user?.name ?? '';
    phone = _account.user?.phone ?? '';
    useNewAddress = _account.addresses.isEmpty;
    quote = _cart.quote(pickup: false);
    refreshQuote();
  }

  final AccountGateway _account;
  final BranchUseCases _branches;
  final CartGateway _cart;
  final OrderGateway _orders;

  String fulfilment = 'delivery';
  String payment = 'razorpay';
  String? selectedAddressId;
  String? pickupBranchId;
  bool useNewAddress = false;
  bool saveAddress = true;
  String name = '';
  String phone = '';
  String? error;
  bool _placed = false;
  late PriceQuote quote;
  int _quoteRequest = 0;

  bool get isPickup => fulfilment == 'pickup';
  bool get paysWithRazorpay => payment == 'razorpay';
  List<Address> get addresses => _account.addresses;
  List<Branch> get branches => _branches.branches;
  UserAccount? get user => _account.user;
  List<CartItem> get items => _cart.items;

  Future<void> refreshQuote() async {
    final request = ++_quoteRequest;
    try {
      final next = await _orders.preview(pickup: isPickup);
      if (request != _quoteRequest) return;
      quote = next;
      notifyListeners();
    } catch (_) {
      if (request != _quoteRequest) return;
      quote = _cart.quote(pickup: isPickup);
      notifyListeners();
    }
  }

  void setFulfilment(String value) {
    fulfilment = value;
    error = null;
    quote = _cart.quote(pickup: isPickup);
    notifyListeners();
    refreshQuote();
  }

  void setPayment(String value) {
    payment = value;
    notifyListeners();
  }

  void selectAddress(String id) {
    selectedAddressId = id;
    useNewAddress = false;
    error = null;
    notifyListeners();
  }

  void selectBranch(String id) {
    pickupBranchId = id;
    error = null;
    notifyListeners();
  }

  void showNewAddress(bool value) {
    useNewAddress = value;
    if (value) selectedAddressId = null;
    error = null;
    notifyListeners();
  }

  void toggleSave(bool value) {
    saveAddress = value;
    notifyListeners();
  }

  void adoptSignedInAddress() {
    final address = _account.defaultAddress;
    name = _account.user?.name ?? name;
    phone = _account.user?.phone ?? phone;
    if (address != null) {
      selectedAddressId = address.id;
      useNewAddress = false;
    }
    error = null;
    notifyListeners();
  }

  void note(String message) {
    error = message;
    notifyListeners();
  }

  CheckoutContact? resolve({
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) {
    if (_placed) return null;
    if (items.isEmpty) {
      error = 'Your cart is empty.';
      notifyListeners();
      return null;
    }

    late final String contactName;
    late final String contactPhone;
    late final String destination;
    var save = false;

    if (isPickup) {
      Branch? branch;
      for (final candidate in branches) {
        if (candidate.id == pickupBranchId) branch = candidate;
      }
      if (branch == null) {
        error = 'Choose a pickup branch.';
        notifyListeners();
        return null;
      }
      final pickupPhone = phone.trim().isNotEmpty ? phone : (user?.phone ?? '');
      if (pickupPhone.replaceAll(RegExp(r'\D'), '').length != 10) {
        error = 'Enter a 10-digit phone number.';
        notifyListeners();
        return null;
      }
      final pickupName = user?.name.isNotEmpty == true ? user!.name : name.trim();
      contactName = pickupName.length < 2 ? 'Store pickup' : pickupName;
      contactPhone = pickupPhone.replaceAll(RegExp(r'\D'), '');
      destination = '${branch.name}, ${branch.address}';
    } else if (!useNewAddress && selectedAddressId != null) {
      Address? address;
      for (final candidate in addresses) {
        if (candidate.id == selectedAddressId) address = candidate;
      }
      if (address == null) {
        error = 'Choose a delivery address.';
        notifyListeners();
        return null;
      }
      contactName = address.name;
      contactPhone = address.phone;
      destination = address.summary;
    } else {
      final problem = _validate(
          name: name, phone: phone, line: line, city: city, pincode: pincode);
      if (problem != null) {
        error = problem;
        notifyListeners();
        return null;
      }
      contactName = name.trim();
      contactPhone = phone.trim();
      destination = '${line.trim()}, ${city.trim()} ${pincode.trim()}';
      save = saveAddress && user != null;
    }

    if (error != null) {
      error = null;
      notifyListeners();
    }
    return CheckoutContact(
      name: contactName,
      phone: contactPhone,
      destination: destination,
      items: List<CartItem>.of(items),
      quote: quote,
      line: line.trim(),
      city: city.trim(),
      pincode: pincode.trim(),
      saveAddress: save,
    );
  }

  Future<ShopOrder?> commit(CheckoutContact contact,
      {String? paymentReference}) async {
    if (_placed) return null;
    if (contact.saveAddress) {
      Address? existing;
      for (final address in _account.addresses) {
        if (address.line.trim() == (contact.line ?? '').trim() &&
            address.pincode == (contact.pincode ?? '').trim()) {
          existing = address;
        }
      }
      await _account.saveAddress(
        id: existing?.id,
        label: existing == null || existing.label.isEmpty ? 'Home' : existing.label,
        name: contact.name,
        phone: contact.phone,
        line: contact.line ?? '',
        city: contact.city ?? '',
        pincode: contact.pincode ?? '',
      );
    }
    try {
      final order = await _orders.place(
        items: contact.items,
        quote: contact.quote,
        fulfilment: fulfilment,
        paymentMethod: payment,
        contactName: contact.name,
        contactPhone: contact.phone,
        destination: contact.destination,
        paymentReference: paymentReference,
        branchId: isPickup ? pickupBranchId : null,
      );
      _placed = true;
      return order;
    } catch (failure) {
      error = failure.toString();
      notifyListeners();
      return null;
    }
  }

  Future<ShopOrder?> place({
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) async {
    final contact = resolve(
        name: name, phone: phone, line: line, city: city, pincode: pincode);
    if (contact == null) return null;
    return commit(contact);
  }

  String? _validate({
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) {
    if (name.trim().length < 2) return 'Enter the recipient name.';
    if (phone.replaceAll(RegExp(r'\D'), '').length != 10) {
      return 'Enter a 10-digit phone number.';
    }
    if (line.trim().length < 5) return 'Enter the house and street.';
    if (city.trim().length < 2) return 'Enter the city.';
    if (pincode.replaceAll(RegExp(r'\D'), '').length != 6) {
      return 'Enter a 6-digit PIN code.';
    }
    return null;
  }
}
