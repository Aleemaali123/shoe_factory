import '../../domain/entities/shop_models.dart';
import '../../domain/pricing/pricing.dart';
import 'shop_mapper.dart';
import 'remote_shop.dart';

class CheckoutApi {
  CheckoutApi(this._api);

  final ShopApi _api;

  Future<PriceQuote> quote({required bool pickup}) async {
    final data = asMap(await _api.post('/api/checkout/quote', {
      'fulfilment': pickup ? 'pickup' : 'delivery',
    }));
    return PriceQuote(
      subtotal: (data['subtotal'] as num).toDouble(),
      discount: (data['discount'] as num).toDouble(),
      deliveryFee: (data['deliveryFee'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      couponCode: data['couponCode'] as String?,
      couponLabel: data['couponLabel'] as String?,
    );
  }

  Future<ShopOrder> place({
    required String fulfilment,
    required String paymentMethod,
    required String contactName,
    required String contactPhone,
    required String destination,
    String? paymentReference,
    String? branchId,
  }) async {
    final data = asMap(await _api.post('/api/checkout', {
      'fulfilment': fulfilment,
      'paymentMethod': paymentMethod,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'destination': destination,
      'paymentReference': paymentReference,
      'branchId': branchId,
    }));
    return orderFromJson(data);
  }
}
