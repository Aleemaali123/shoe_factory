class Coupon {
  const Coupon({
    required this.code,
    required this.label,
    this.percent = 0,
    this.flatOff = 0,
    this.freeShipping = false,
    this.minSubtotal = 0,
  });

  final String code;
  final String label;
  final double percent;
  final double flatOff;
  final bool freeShipping;
  final double minSubtotal;
}

class PriceQuote {
  const PriceQuote({
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    this.couponCode,
    this.couponLabel,
  });

  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? couponCode;
  final String? couponLabel;
}

class CouponAttempt {
  const CouponAttempt(
      {required this.accepted, required this.message, required this.quote});

  final bool accepted;
  final String message;
  final PriceQuote quote;
}

class Pricing {
  static const freeDeliveryThreshold = 4999.0;
  static const standardDelivery = 49.0;

  static const coupons = <Coupon>[
    Coupon(code: 'TREND10', label: '10% off', percent: 10),
    Coupon(
        code: 'FACTORY200',
        label: '₹200 off above ₹1,999',
        flatOff: 200,
        minSubtotal: 1999),
    Coupon(
        code: 'FREESHIP',
        label: 'Free delivery above ₹999',
        freeShipping: true,
        minSubtotal: 999),
  ];

  static Coupon? find(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final key = code.trim().toUpperCase();
    for (final coupon in coupons) {
      if (coupon.code == key) return coupon;
    }
    return null;
  }

  static PriceQuote calculate(
      {required double subtotal, String? couponCode, required bool pickup}) {
    final coupon = find(couponCode);
    var discount = 0.0;
    var freeShipping = false;
    String? appliedCode;
    String? appliedLabel;
    if (coupon != null && subtotal >= coupon.minSubtotal) {
      if (coupon.percent > 0) {
        discount += (subtotal * coupon.percent / 100).roundToDouble();
      }
      if (coupon.flatOff > 0) discount += coupon.flatOff;
      freeShipping = coupon.freeShipping;
      appliedCode = coupon.code;
      appliedLabel = coupon.label;
    }
    if (discount > subtotal) discount = subtotal;
    final delivery = _delivery(
        subtotal: subtotal, pickup: pickup, freeShipping: freeShipping);
    final total =
        (subtotal - discount + delivery).clamp(0, double.infinity).toDouble();
    return PriceQuote(
      subtotal: subtotal,
      discount: discount,
      deliveryFee: delivery,
      total: total,
      couponCode: appliedCode,
      couponLabel: appliedLabel,
    );
  }

  static CouponAttempt evaluate(
      {required double subtotal,
      required String rawCode,
      required bool pickup}) {
    final code = rawCode.trim().toUpperCase();
    final plain = calculate(subtotal: subtotal, pickup: pickup);
    if (code.isEmpty) {
      return CouponAttempt(
          accepted: false, message: 'Enter a coupon code.', quote: plain);
    }
    final coupon = find(code);
    if (coupon == null) {
      return CouponAttempt(
        accepted: false,
        message:
            'That code is not recognised. Try TREND10, FACTORY200 or FREESHIP.',
        quote: plain,
      );
    }
    if (subtotal < coupon.minSubtotal) {
      return CouponAttempt(
        accepted: false,
        message: 'Add a little more to your cart to use ${coupon.code}.',
        quote: plain,
      );
    }
    final quote =
        calculate(subtotal: subtotal, couponCode: code, pickup: pickup);
    final message = pickup && coupon.freeShipping
        ? 'Store pickup is already free. ${coupon.code} is saved on this order.'
        : '${coupon.code} applied. ${coupon.label}.';
    return CouponAttempt(accepted: true, message: message, quote: quote);
  }

  static double _delivery(
      {required double subtotal,
      required bool pickup,
      required bool freeShipping}) {
    if (pickup || subtotal <= 0) return 0;
    if (freeShipping || subtotal >= freeDeliveryThreshold) return 0;
    return standardDelivery;
  }
}
