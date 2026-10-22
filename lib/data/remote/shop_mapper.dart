import '../../domain/entities/shop_models.dart';

Product productFromJson(Map<String, dynamic> json) {
  return Product(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    price: (json['price'] as num).toDouble(),
    oldPrice: (json['oldPrice'] as num).toDouble(),
    rating: (json['rating'] as num).toDouble(),
    reviewCount: (json['reviewCount'] as num).toInt(),
    imageUrls: [for (final url in json['imageUrls'] as List) url as String],
    description: json['description'] as String,
    colors: [for (final color in json['colors'] as List) color as String],
    sizes: [for (final size in json['sizes'] as List) (size as num).toInt()],
    stock: (json['stock'] as num).toInt(),
    reviews: [
      for (final review in json['reviews'] as List? ?? const [])
        ProductReview(
          author: review['author'] as String,
          rating: (review['rating'] as num).toDouble(),
          comment: review['comment'] as String,
        ),
    ],
    badge: json['badge'] as String?,
    isNew: json['isNew'] as bool? ?? false,
  );
}

CartItem cartItemFromJson(Map<String, dynamic> json) {
  return CartItem(
    id: json['id'] as String,
    productId: json['productId'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    color: json['color'] as String,
    size: (json['size'] as num).toInt(),
    quantity: (json['quantity'] as num).toInt(),
  );
}

OrderLine orderLineFromJson(Map<String, dynamic> json) {
  return OrderLine(
    productId: json['productId'] as String,
    name: json['name'] as String,
    imageUrl: json['imageUrl'] as String,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    color: json['color'] as String,
    size: (json['size'] as num).toInt(),
    quantity: (json['quantity'] as num).toInt(),
  );
}

ShopOrder orderFromJson(Map<String, dynamic> json) {
  return ShopOrder(
    id: json['id'] as String,
    placedAt: DateTime.parse(json['placedAt'] as String),
    lines: [
      for (final line in json['lines'] as List)
        orderLineFromJson(Map<String, dynamic>.from(line as Map)),
    ],
    subtotal: (json['subtotal'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    deliveryFee: (json['deliveryFee'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    fulfilment: json['fulfilment'] as String,
    paymentMethod: json['paymentMethod'] as String,
    status: OrderStatus.values
        .firstWhere((value) => value.name == json['status']),
    destination: json['destination'] as String,
    contactName: json['contactName'] as String,
    contactPhone: json['contactPhone'] as String,
    couponCode: json['couponCode'] as String?,
    paymentReference: json['paymentReference'] as String?,
  );
}

Address addressFromJson(Map<String, dynamic> json) {
  return Address(
    id: json['id'] as String,
    label: json['label'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    line: json['line'] as String,
    city: json['city'] as String,
    pincode: json['pincode'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}

UserAccount userFromJson(Map<String, dynamic> json) {
  return UserAccount(
    name: json['name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
  );
}

Branch branchFromJson(Map<String, dynamic> json) {
  return Branch(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
    hours: json['hours'] as String,
    phone: json['phone'] as String,
  );
}

ShopNotice noticeFromJson(Map<String, dynamic> json) {
  return ShopNotice(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    timeLabel: json['timeLabel'] as String,
    read: json['read'] as bool? ?? false,
  );
}

Map<String, dynamic> asMap(Object? value) =>
    Map<String, dynamic>.from(value as Map);
