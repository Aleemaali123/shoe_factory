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
