import '../entities/shop_models.dart';

abstract class CatalogRepository {
  List<Product> get products;
  Stream<List<Product>> watch();
  Product? findById(String id);
  void replaceAll(List<Product> products);
  void upsert(Product product);
}

abstract class CartRepository {
  List<CartItem> get items;
  String? get couponCode;
  void upsert(CartItem item);
  void remove(String id);
  void clear();
  void setCoupon(String? code);
}

abstract class WishlistRepository {
  List<String> get ids;
  bool contains(String id);
  void toggle(String id);
}

abstract class OrderRepository {
  List<ShopOrder> get orders;
  ShopOrder? find(String id);
  void add(ShopOrder order);
  void update(ShopOrder order);
  String nextId();
}

abstract class AccountRepository {
  UserAccount? get user;
  List<Address> get addresses;
  bool hasEmail(String email);
  UserAccount? findByPhone(String phone);
  void saveCredential(UserAccount account, String password);
  UserAccount? authenticate(String email, String password);
  bool changePassword(String email, String password);
  void signIn(UserAccount account);
  void signOut();
  void update(UserAccount account);
  void saveAddress(Address address);
  void deleteAddress(String id);
  void setDefault(String id);
}

abstract class BranchRepository {
  List<Branch> get branches;
  Branch get selected;
  void select(String id);
}

abstract class NoticeRepository {
  List<ShopNotice> get notices;
  void markAllRead();
}
