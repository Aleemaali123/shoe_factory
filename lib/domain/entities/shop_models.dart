enum ProductSort {
  featured('Featured'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  rating('Top rated'),
  newest('New arrivals');

  const ProductSort(this.label);
  final String label;
}

enum OrderStatus { confirmed, preparing, onTheWay, completed, cancelled }

class ProductReview {
  const ProductReview(
      {required this.author, required this.rating, required this.comment});

  final String author;
  final double rating;
  final String comment;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.imageUrls,
    required this.description,
    required this.colors,
    required this.sizes,
    required this.stock,
    required this.reviews,
    this.badge,
    this.isNew = false,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double oldPrice;
  final double rating;
  final int reviewCount;
  final List<String> imageUrls;
  final String description;
  final String? badge;
  final List<String> colors;
  final List<int> sizes;
  final int stock;
  final bool isNew;
  final List<ProductReview> reviews;

  String get imageUrl => imageUrls.first;

  int get discountPercent =>
      oldPrice <= price ? 0 : (((oldPrice - price) / oldPrice) * 100).round();

  bool get lowStock => stock > 0 && stock <= 5;
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.color,
    required this.size,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final String color;
  final int size;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      imageUrl: imageUrl,
      unitPrice: unitPrice,
      color: color,
      size: size,
      quantity: quantity ?? this.quantity,
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.color,
    required this.size,
    required this.quantity,
  });

  final String productId;
  final String name;
  final String imageUrl;
  final double unitPrice;
  final String color;
  final int size;
  final int quantity;

  double get lineTotal => unitPrice * quantity;
}

class ShopOrder {
  const ShopOrder({
    required this.id,
    required this.placedAt,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.fulfilment,
    required this.paymentMethod,
    required this.status,
    required this.destination,
    required this.contactName,
    required this.contactPhone,
    this.couponCode,
    this.paymentReference,
  });

  final String id;
  final DateTime placedAt;
  final List<OrderLine> lines;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String fulfilment;
  final String paymentMethod;
  final OrderStatus status;
  final String destination;
  final String contactName;
  final String contactPhone;
  final String? couponCode;
  final String? paymentReference;

  bool get isPickup => fulfilment == 'pickup';
  bool get canCancel =>
      status == OrderStatus.confirmed || status == OrderStatus.preparing;
  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  String get summary {
    if (lines.isEmpty) return 'No items';
    if (lines.length == 1) return lines.first.name;
    return '${lines.first.name} + ${lines.length - 1} more';
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.onTheWay:
        return isPickup ? 'Ready for pickup' : 'Out for delivery';
      case OrderStatus.completed:
        return isPickup ? 'Collected' : 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get eta {
    if (status == OrderStatus.cancelled) return 'This order was cancelled';
    if (status == OrderStatus.completed) {
      return isPickup ? 'Collected from the branch' : 'Delivered';
    }
    return isPickup
        ? 'Ready for pickup in 1–2 days'
        : 'Estimated delivery in 2–4 days';
  }

  int get stepIndex {
    switch (status) {
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.onTheWay:
        return 2;
      case OrderStatus.completed:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  ShopOrder copyWith({OrderStatus? status}) {
    return ShopOrder(
      id: id,
      placedAt: placedAt,
      lines: lines,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      total: total,
      fulfilment: fulfilment,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      destination: destination,
      contactName: contactName,
      contactPhone: contactPhone,
      couponCode: couponCode,
      paymentReference: paymentReference,
    );
  }
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.line,
    required this.city,
    required this.pincode,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String line;
  final String city;
  final String pincode;
  final bool isDefault;

  String get summary => '$line, $city $pincode';

  Address copyWith({bool? isDefault}) {
    return Address(
      id: id,
      label: label,
      name: name,
      phone: phone,
      line: line,
      city: city,
      pincode: pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class UserAccount {
  const UserAccount(
      {required this.name, required this.email, required this.phone});

  final String name;
  final String email;
  final String phone;
}

class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
    required this.phone,
  });

  final String id;
  final String name;
  final String address;
  final String hours;
  final String phone;
}

class CustomerPlace {
  const CustomerPlace({
    required this.area,
    required this.city,
    this.fromDevice = false,
  });

  final String area;
  final String city;
  final bool fromDevice;

  String get label {
    final areaText = area.trim();
    final cityText = city.trim();
    if (areaText.isEmpty) return cityText;
    if (cityText.isEmpty || areaText.toLowerCase() == cityText.toLowerCase()) {
      return areaText;
    }
    return '$areaText, $cityText';
  }
}

class ShopNotice {
  const ShopNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    this.read = false,
    this.kind = 'info',
    this.targetId = '',
  });

  final String id;
  final String title;
  final String body;
  final String timeLabel;
  final bool read;
  final String kind;
  final String targetId;

  ShopNotice copyWith({
    bool? read,
    String? title,
    String? body,
    String? timeLabel,
    String? kind,
    String? targetId,
  }) {
    return ShopNotice(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      timeLabel: timeLabel ?? this.timeLabel,
      read: read ?? this.read,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
    );
  }
}
