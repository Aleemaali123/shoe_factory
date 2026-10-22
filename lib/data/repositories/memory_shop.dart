import 'dart:async';

import '../../domain/entities/shop_models.dart';
import '../../domain/repositories/shop_repositories.dart';

class MemoryCatalogRepository implements CatalogRepository {
  MemoryCatalogRepository(List<Product> products) : _products = List.of(products);

  final List<Product> _products;
  final StreamController<List<Product>> _updates =
      StreamController<List<Product>>.broadcast();

  @override
  List<Product> get products => List.unmodifiable(_products);

  @override
  Stream<List<Product>> watch() {
    return Stream<List<Product>>.multi((listener) {
      listener.add(List.unmodifiable(_products));
      final subscription = _updates.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Product? findById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  void replaceAll(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
    if (!_updates.isClosed) _updates.add(List.unmodifiable(_products));
  }

  @override
  void upsert(Product product) {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    } else {
      _products.add(product);
    }
    if (!_updates.isClosed) _updates.add(List.unmodifiable(_products));
  }
}

class MemoryCartRepository implements CartRepository {
  final List<CartItem> _items = [];
  String? _coupon;

  @override
  List<CartItem> get items => List.unmodifiable(_items);

  @override
  String? get couponCode => _coupon;

  @override
  void upsert(CartItem item) {
    final index = _items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
  }

  @override
  void remove(String id) => _items.removeWhere((item) => item.id == id);

  @override
  void clear() {
    _items.clear();
    _coupon = null;
  }

  @override
  void setCoupon(String? code) => _coupon = code;
}

class MemoryWishlistRepository implements WishlistRepository {
  final List<String> _ids = [];

  @override
  List<String> get ids => List.unmodifiable(_ids);

  @override
  bool contains(String id) => _ids.contains(id);

  @override
  void toggle(String id) {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.insert(0, id);
    }
  }
}

class MemoryOrderRepository implements OrderRepository {
  MemoryOrderRepository(List<ShopOrder> seed) : _orders = List.of(seed);

  final List<ShopOrder> _orders;
  int _next = 10242;

  @override
  List<ShopOrder> get orders => List.unmodifiable(_orders);

  @override
  ShopOrder? find(String id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  @override
  void add(ShopOrder order) => _orders.insert(0, order);

  @override
  void update(ShopOrder order) {
    final index = _orders.indexWhere((existing) => existing.id == order.id);
    if (index >= 0) _orders[index] = order;
  }

  @override
  String nextId() => 'SF-${_next++}';
}

class _Login {
  _Login({required this.account, required this.password});

  UserAccount account;
  String password;
}

class MemoryAccountRepository implements AccountRepository {
  MemoryAccountRepository() {
    saveCredential(
      const UserAccount(
        name: 'Shoe Factory Shopper',
        email: 'shopper@shoefactory.shop',
        phone: '9876543210',
      ),
      'trend',
    );
  }

  UserAccount? _user;
  final List<Address> _addresses = [];
  final Map<String, _Login> _directory = {};

  String _key(String email) => email.trim().toLowerCase();

  @override
  UserAccount? get user => _user;

  @override
  List<Address> get addresses => List.unmodifiable(_addresses);

  @override
  bool hasEmail(String email) => _directory.containsKey(_key(email));

  @override
  UserAccount? findByPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    for (final login in _directory.values) {
      if (login.account.phone == digits) return login.account;
    }
    return null;
  }

  @override
  void saveCredential(UserAccount account, String password) {
    _directory[_key(account.email)] =
        _Login(account: account, password: password);
  }

  @override
  UserAccount? authenticate(String email, String password) {
    final login = _directory[_key(email)];
    if (login == null || login.password != password) return null;
    return login.account;
  }

  @override
  bool changePassword(String email, String password) {
    final login = _directory[_key(email)];
    if (login == null) return false;
    login.password = password;
    return true;
  }

  @override
  void signIn(UserAccount account) => _user = account;

  @override
  void signOut() => _user = null;

  @override
  void update(UserAccount account) {
    final previousEmail = _user?.email;
    if (previousEmail != null) {
      final login = _directory.remove(_key(previousEmail));
      if (login != null) {
        _directory[_key(account.email)] =
            _Login(account: account, password: login.password);
      }
    }
    _user = account;
  }

  @override
  void saveAddress(Address address) {
    if (address.isDefault) {
      for (var i = 0; i < _addresses.length; i++) {
        if (_addresses[i].id != address.id) {
          _addresses[i] = _addresses[i].copyWith(isDefault: false);
        }
      }
    }
    final index =
        _addresses.indexWhere((existing) => existing.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    if (_addresses.isNotEmpty && _addresses.every((item) => !item.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
  }

  @override
  void deleteAddress(String id) {
    _addresses.removeWhere((address) => address.id == id);
    if (_addresses.isNotEmpty && _addresses.every((item) => !item.isDefault)) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
  }

  @override
  void setDefault(String id) {
    for (var i = 0; i < _addresses.length; i++) {
      _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == id);
    }
  }
}

class MemoryBranchRepository implements BranchRepository {
  MemoryBranchRepository(List<Branch> branches)
      : _branches = List.of(branches),
        _selectedId = branches.first.id;

  final List<Branch> _branches;
  String _selectedId;

  @override
  List<Branch> get branches => List.unmodifiable(_branches);

  @override
  Branch get selected {
    for (final branch in _branches) {
      if (branch.id == _selectedId) return branch;
    }
    return _branches.first;
  }

  @override
  void select(String id) {
    for (final branch in _branches) {
      if (branch.id == id) _selectedId = id;
    }
  }

  void replace(List<Branch> branches) {
    if (branches.isEmpty) return;
    _branches
      ..clear()
      ..addAll(branches);
    var kept = false;
    for (final branch in _branches) {
      if (branch.id == _selectedId) kept = true;
    }
    if (!kept) _selectedId = _branches.first.id;
  }
}

class MemoryNoticeRepository implements NoticeRepository {
  MemoryNoticeRepository(List<ShopNotice> notices)
      : _notices = List.of(notices);

  final List<ShopNotice> _notices;

  @override
  List<ShopNotice> get notices => List.unmodifiable(_notices);

  @override
  void markAllRead() {
    for (var i = 0; i < _notices.length; i++) {
      _notices[i] = _notices[i].copyWith(read: true);
    }
  }

  @override
  void markRead(String id) {
    final index = _notices.indexWhere((notice) => notice.id == id);
    if (index < 0) return;
    _notices[index] = _notices[index].copyWith(read: true);
  }

  @override
  void dismiss(String id) {
    _notices.removeWhere((notice) => notice.id == id);
  }

  @override
  void push(ShopNotice notice) {
    _notices.removeWhere((item) => item.id == notice.id);
    _notices.insert(0, notice);
  }
}
