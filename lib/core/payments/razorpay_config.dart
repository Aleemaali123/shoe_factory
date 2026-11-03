/// Runtime Razorpay Key Id from the shop API (`GET /api/payments/razorpay`).
///
/// Credentials live in the backend `.env` only. The Flutter app never embeds
/// the Key Secret; it only receives the public Key Id when payments are enabled.
String razorpayKeyId = '';

/// `test` or `live` from the API, or empty when online payment is off.
String razorpayMode = '';

bool get razorpayConfigured =>
    razorpayKeyId.isNotEmpty &&
    razorpayKeyId != 'rzp_test_1DP5mmOlF5G5ag';

/// Local dialog fallback when the backend has no Razorpay keys configured.
bool get usesDemoOnlinePayment => !razorpayConfigured;

void applyRazorpayConfig({required bool enabled, String? keyId, String? mode}) {
  if (!enabled || keyId == null || keyId.trim().isEmpty) {
    razorpayKeyId = '';
    razorpayMode = '';
    return;
  }
  razorpayKeyId = keyId.trim();
  razorpayMode = (mode ?? '').trim();
}
