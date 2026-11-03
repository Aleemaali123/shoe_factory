String formatRupees(num amount) {
  final negative = amount < 0;
  final whole = amount.round().abs().toString();
  final formatted = _indianGroup(whole);
  return negative ? '-₹$formatted' : '₹$formatted';
}

String _indianGroup(String whole) {
  if (whole.length <= 3) return whole;
  final last3 = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '${parts.join(',')},$last3';
}

String sizeHeading(String category) {
  switch (category) {
    case 'Watches':
      return 'Case size';
    case 'Perfumes':
      return 'Volume';
    case 'Caps':
      return 'Head size';
    default:
      return 'Size (UK)';
  }
}

String sizeOption(String? category, int size) {
  switch (category) {
    case 'Watches':
      return '$size mm';
    case 'Perfumes':
      return '$size ml';
    case 'Caps':
      return '$size cm';
    default:
      return 'UK $size';
  }
}

String sizeGuide(String category) {
  switch (category) {
    case 'Watches':
      return 'Case size is the width of the watch face in millimetres. 40 mm wears smaller and 42 mm wears larger.';
    case 'Perfumes':
      return 'Volume is the bottle size in millilitres. 50 ml is easy to carry. 100 ml is the full bottle.';
    case 'Caps':
      return 'Head size is the circumference in centimetres. If you are between sizes, choose the larger one.';
    case 'Socks':
      return 'Sock size follows your usual UK shoe size.';
    default:
      return 'Choose your usual UK size. If you are between sizes, the next size up is the safer fit for sneakers and boots. Sandals can follow your regular size.';
  }
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String paymentLabel(String method) {
  switch (method) {
    case 'razorpay':
      return 'Razorpay';
    case 'upi':
      return 'UPI';
    case 'card':
      return 'Credit / debit card';
    case 'cod':
      return 'Cash on delivery';
    default:
      return method;
  }
}

String fulfilmentLabel(String value) =>
    value == 'pickup' ? 'Store pickup' : 'Home delivery';

String deliveryFeeLabel(double fee,
    {required bool pickup, required double subtotal}) {
  if (pickup || (fee <= 0 && subtotal > 0)) return 'Free';
  return formatRupees(fee);
}
