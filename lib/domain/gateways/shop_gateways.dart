import '../entities/shop_models.dart';
import '../pricing/pricing.dart';
import '../usecases/shop_results.dart';

abstract class CartGateway {
  List<CartItem> get items;
  String? get couponCode;
  int get count;
  double get subtotal;
  PriceQuote quote({required bool pickup});
  Future<AddToCartResult> add(Product product,
      {required int size, required String color, int quantity = 1});
  Future<void> setQuantity(String id, int quantity);
  Future<void> remove(String id);
  Future<CouponAttempt> applyCoupon(String code, {required bool pickup});
  Future<void> clearCoupon();
  Future<void> clear();
}

abstract class WishlistGateway {
  List<Product> get products;
  bool contains(String id);
  Future<void> toggle(String id);
}

abstract class OrderGateway {
  List<ShopOrder> get orders;
  ShopOrder? byId(String id);
  Future<PriceQuote> preview({required bool pickup});
  Future<ShopOrder> place({
    required List<CartItem> items,
    required PriceQuote quote,
    required String fulfilment,
    required String paymentMethod,
    required String contactName,
    required String contactPhone,
    required String destination,
    String? paymentReference,
  });
  Future<bool> cancel(String id);
  Future<int> reorder(ShopOrder order);
}

abstract class AccountGateway {
  UserAccount? get user;
  List<Address> get addresses;
  Address? get defaultAddress;
  Future<OtpRequest> requestOtp(String phone);
  Future<OtpSignIn> verifyOtp({required String phone, required String code});
  Future<String?> registerWithOtp({
    required String name,
    required String email,
    required String phone,
    required String code,
  });
  Future<String?> signInWithPassword(
      {required String email, required String password});
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  });
  Future<String?> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
  });
  Future<void> signOut();
  Future<String?> updateProfile(
      {required String name, required String email, required String phone});
  Future<String?> saveAddress({
    String? id,
    required String label,
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  });
  Future<void> deleteAddress(String id);
  Future<void> setDefault(String id);
}

abstract class NoticeGateway {
  List<ShopNotice> get notices;
  int get unread;
  Future<void> markAllRead();
}
