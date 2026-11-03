import '../../core/payments/razorpay_config.dart';
import 'remote_shop.dart';
import 'shop_mapper.dart';

class RazorpayOrderSession {
  const RazorpayOrderSession({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.mode,
  });

  final String keyId;
  final String orderId;
  final int amountPaise;
  final String currency;
  final String mode;
}

class PaymentsApi {
  PaymentsApi(this._api);

  final ShopApi _api;

  Future<void> refreshConfig() async {
    final data = asMap(await _api.get('/api/payments/razorpay'));
    applyRazorpayConfig(
      enabled: data['enabled'] == true,
      keyId: data['keyId'] as String?,
      mode: data['mode'] as String?,
    );
  }

  Future<RazorpayOrderSession> createOrder({
    required int amountPaise,
    String? receipt,
  }) async {
    final data = asMap(await _api.post('/api/payments/razorpay/orders', {
      'amountPaise': amountPaise,
      if (receipt != null && receipt.isNotEmpty) 'receipt': receipt,
    }));
    final keyId = (data['keyId'] as String? ?? '').trim();
    final orderId = (data['orderId'] as String? ?? '').trim();
    if (keyId.isEmpty || orderId.isEmpty) {
      throw StateError('Razorpay did not return a checkout session.');
    }
    applyRazorpayConfig(
      enabled: true,
      keyId: keyId,
      mode: data['mode'] as String?,
    );
    return RazorpayOrderSession(
      keyId: keyId,
      orderId: orderId,
      amountPaise: (data['amount'] as num?)?.round() ?? amountPaise,
      currency: (data['currency'] as String?) ?? 'INR',
      mode: (data['mode'] as String?) ?? '',
    );
  }
}
