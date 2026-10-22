import '../../domain/entities/shop_models.dart';
import '../../domain/pricing/pricing.dart';

String _img(String id) =>
    'https://images.unsplash.com/$id?auto=format&fit=crop&w=900&q=80';

ProductReview _review(double rating, String comment) {
  return ProductReview(
      author: 'Verified buyer', rating: rating, comment: comment);
}

Product _shoe({
  required String id,
  required String name,
  required String category,
  required double price,
  required double oldPrice,
  required double rating,
  required int reviewCount,
  required List<String> images,
  required String description,
  required List<ProductReview> reviews,
  String? badge,
  List<String> colors = const ['Black', 'White'],
  List<int> sizes = const [6, 7, 8, 9, 10, 11],
  int stock = 12,
  bool isNew = false,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    price: price,
    oldPrice: oldPrice,
    rating: rating,
    reviewCount: reviewCount,
    imageUrls: images.map(_img).toList(),
    description: description,
    badge: badge,
    colors: colors,
    sizes: sizes,
    stock: stock,
    isNew: isNew,
    reviews: reviews,
  );
}

final demoProducts = <Product>[
  _shoe(
    id: 'sf001',
    name: 'Air Motion Runner',
    category: 'Sneakers',
    price: 6499,
    oldPrice: 7999,
    rating: 4.6,
    reviewCount: 128,
    images: const [
      'photo-1542291026-7eec264c27ff',
      'photo-1606107557195-0e29a4b5b4aa'
    ],
    description:
        'Lightweight everyday sneakers with cushioned support, a breathable upper and a bold streetwear look.',
    badge: 'BESTSELLER',
    colors: const ['Red', 'Black', 'White'],
    stock: 8,
    reviews: const [
      ProductReview(
          author: 'Verified buyer',
          rating: 5,
          comment: 'Light on the feet and easy to dress up or down.'),
      ProductReview(
          author: 'Verified buyer',
          rating: 4,
          comment: 'True to size. The cushioning holds up on long days.'),
    ],
  ),
  _shoe(
    id: 'sf002',
    name: 'Cloud Knit Sneaker',
    category: 'Sneakers',
    price: 5299,
    oldPrice: 6499,
    rating: 4.5,
    reviewCount: 67,
    images: const [
      'photo-1600185365483-26d7a4cc7519',
      'photo-1539185441755-769473a23570'
    ],
    description:
        'A soft knit sneaker with a clean profile for workdays, weekends and everything between.',
    colors: const ['White', 'Grey', 'Green'],
    stock: 10,
    reviews: [
      _review(5, 'The knit upper feels soft from the first wear.'),
      _review(4, 'Looks sharp with both jeans and tailored trousers.'),
    ],
  ),
  _shoe(
    id: 'sf003',
    name: 'Urban Flex Trainer',
    category: 'Sports',
    price: 8999,
    oldPrice: 11999,
    rating: 4.8,
    reviewCount: 96,
    images: const [
      'photo-1460353581641-37baddab0fa2',
      'photo-1595950653106-6c9ebd614d3a'
    ],
    description:
        'A versatile trainer built for movement, gym sessions and comfortable all-day wear.',
    badge: '25% OFF',
    colors: const ['Black', 'Green', 'Grey'],
    stock: 6,
    reviews: [
      _review(5, 'Excellent grip and the fit stays secure on runs.'),
      _review(4, 'Worth it. I wear them for training and travel.'),
    ],
  ),
  _shoe(
    id: 'sf004',
    name: 'Trail Pro Outdoor',
    category: 'Sports',
    price: 7499,
    oldPrice: 8999,
    rating: 4.5,
    reviewCount: 61,
    images: const ['photo-1552346154-21d32810aba3'],
    description:
        'Durable grip and dependable comfort for weekend trails and active days.',
    badge: 'NEW',
    colors: const ['Brown', 'Black', 'Green'],
    stock: 9,
    isNew: true,
    reviews: [
      _review(5, 'Sturdy without feeling heavy. Great for weekend walks.'),
      _review(4, 'The outsole grips well on wet paths.'),
    ],
  ),
  _shoe(
    id: 'sf005',
    name: 'Night Runner Pro',
    category: 'Sports',
    price: 9999,
    oldPrice: 12999,
    rating: 4.9,
    reviewCount: 84,
    images: const ['photo-1491553895911-0055eca6402d'],
    description:
        'Our most cushioned runner, with a responsive feel for daily miles and race day.',
    badge: 'BESTSELLER',
    colors: const ['Black', 'Grey'],
    stock: 3,
    reviews: [
      _review(5, 'The best cushioning I have worn from Shoe Factory.'),
      _review(5, 'Fast, stable and still comfortable after 10 km.'),
    ],
  ),
  _shoe(
    id: 'sf006',
    name: 'Classic Court Low',
    category: 'Casual',
    price: 4499,
    oldPrice: 5499,
    rating: 4.4,
    reviewCount: 74,
    images: const ['photo-1549298916-b41d501d3772'],
    description:
        'A timeless low-top silhouette that pairs easily with your everyday wardrobe.',
    colors: const ['White', 'Navy', 'Black'],
    stock: 14,
    reviews: [
      _review(4, 'Clean look. I sized up by half and they are perfect.'),
      _review(5, 'A reliable everyday pair. The leather is wearing in nicely.'),
    ],
  ),
  _shoe(
    id: 'sf007',
    name: 'Everyday Slip-On',
    category: 'Casual',
    price: 2999,
    oldPrice: 3499,
    rating: 4.3,
    reviewCount: 48,
    images: const ['photo-1560769629-975ec94e6a86'],
    description:
        'Easy to wear and easy to style. A relaxed slip-on for errands and travel days.',
    colors: const ['Black', 'White'],
    stock: 20,
    reviews: [
      _review(4, 'Slips on easily and still feels supported.'),
      _review(4, 'Bright colour, exactly as pictured.'),
    ],
  ),
  _shoe(
    id: 'sf008',
    name: 'Weekend Boot',
    category: 'Casual',
    price: 3999,
    oldPrice: 4999,
    rating: 4.2,
    reviewCount: 58,
    images: const ['photo-1514989940723-e8e51635b782'],
    description:
        'A rugged boot with a soft lining for cooler days, denim and weekend plans.',
    colors: const ['Brown', 'Black'],
    sizes: const [6, 7, 8, 9, 10],
    stock: 7,
    reviews: [
      _review(4, 'Solid build. They needed one wear to soften up.'),
      _review(4, 'Comfortable for a full day around the city.'),
    ],
  ),
  _shoe(
    id: 'sf009',
    name: 'Executive Formal',
    category: 'Formal',
    price: 5999,
    oldPrice: 6999,
    rating: 4.7,
    reviewCount: 53,
    images: const ['photo-1533867617858-e7b97e060509'],
    description:
        'A polished formal shoe with a refined profile for work, celebrations and special occasions.',
    colors: const ['Brown', 'Black'],
    stock: 7,
    reviews: [
      _review(5, 'Looks expensive and feels comfortable in the office.'),
      _review(4, 'Elegant finish. The brown colour is rich.'),
    ],
  ),
  _shoe(
    id: 'sf010',
    name: 'Heritage Loafer',
    category: 'Formal',
    price: 6799,
    oldPrice: 7999,
    rating: 4.6,
    reviewCount: 41,
    images: const ['photo-1614252369475-5312f9b6c2f5'],
    description:
        'A leather loafer with a quiet shape that works from meetings to dinner.',
    colors: const ['Brown', 'Black'],
    stock: 6,
    reviews: [
      _review(5, 'Smart without being stiff. I wear them every week.'),
      _review(4, 'Beautiful leather. Take your usual size.'),
    ],
  ),
  _shoe(
    id: 'sf011',
    name: 'Coastline Sandal',
    category: 'Sandals',
    price: 1999,
    oldPrice: 2499,
    rating: 4.4,
    reviewCount: 39,
    images: const ['photo-1603487742131-4160ec999306'],
    description:
        'An easy warm-weather sandal with a cushioned footbed and an adjustable strap.',
    badge: 'NEW',
    colors: const ['Beige', 'Brown', 'Black'],
    sizes: const [6, 7, 8, 9, 10],
    stock: 11,
    isNew: true,
    reviews: [
      _review(5, 'Comfortable straight out of the box.'),
      _review(4, 'The strap holds well on long walks.'),
    ],
  ),
  _shoe(
    id: 'sf012',
    name: 'Monsoon Slide',
    category: 'Sandals',
    price: 1499,
    oldPrice: 1899,
    rating: 4.1,
    reviewCount: 33,
    images: const ['photo-1562273138-f46be4ebdf33'],
    description: 'A quick-dry slide for rain, home and everything in between.',
    badge: 'TRENDING',
    colors: const ['Green', 'Black', 'Beige'],
    sizes: const [6, 7, 8, 9, 10],
    stock: 4,
    isNew: true,
    reviews: [
      _review(4, 'Light and easy to rinse after the rain.'),
      _review(4, 'Good grip on wet tile.'),
    ],
  ),
];

const demoBranches = <Branch>[
  Branch(
    id: 'tvm',
    name: 'Trivandrum Central',
    address: 'MG Road, Thiruvananthapuram',
    hours: 'Open today · 10:00 AM–9:00 PM',
    phone: '0471 555 0101',
  ),
  Branch(
    id: 'kochi',
    name: 'Kochi Marine Drive',
    address: 'Marine Drive, Kochi',
    hours: 'Open today · 10:00 AM–9:30 PM',
    phone: '0484 555 0118',
  ),
  Branch(
    id: 'clt',
    name: 'Calicut Main',
    address: 'Mavoor Road, Kozhikode',
    hours: 'Open today · 10:00 AM–9:00 PM',
    phone: '0495 555 0134',
  ),
];

const demoNotices = <ShopNotice>[
  ShopNotice(
    id: 'n1',
    title: 'Your order is being prepared',
    body: 'SF-10241 is being packed at Trivandrum Central.',
    timeLabel: 'Today',
  ),
  ShopNotice(
    id: 'n2',
    title: 'TREND10 is live this week',
    body: 'Take 10% off your cart with code TREND10.',
    timeLabel: 'Yesterday',
  ),
  ShopNotice(
    id: 'n3',
    title: 'New sandals just landed',
    body: 'Coastline Sandal and Monsoon Slide are in store and online.',
    timeLabel: 'This week',
  ),
];

OrderLine _line(Product product,
    {required int size, required String color, int quantity = 1}) {
  return OrderLine(
    productId: product.id,
    name: product.name,
    imageUrl: product.imageUrl,
    unitPrice: product.price,
    color: color,
    size: size,
    quantity: quantity,
  );
}

List<ShopOrder> buildSeedOrders() {
  Product byId(String id) =>
      demoProducts.firstWhere((product) => product.id == id);
  final runner = byId('sf001');
  final court = byId('sf006');
  final now = DateTime.now();

  ShopOrder make({
    required String id,
    required DateTime placedAt,
    required List<OrderLine> lines,
    required OrderStatus status,
    required String paymentMethod,
    String? couponCode,
  }) {
    final subtotal = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
    final quote = Pricing.calculate(
        subtotal: subtotal, couponCode: couponCode, pickup: false);
    return ShopOrder(
      id: id,
      placedAt: placedAt,
      lines: lines,
      subtotal: quote.subtotal,
      discount: quote.discount,
      deliveryFee: quote.deliveryFee,
      total: quote.total,
      fulfilment: 'delivery',
      paymentMethod: paymentMethod,
      status: status,
      destination: '12, MG Road, Thiruvananthapuram 695001',
      contactName: 'Shoe Factory Shopper',
      contactPhone: '9876543210',
      couponCode: quote.couponCode,
    );
  }

  return [
    make(
      id: 'SF-10241',
      placedAt: now.subtract(const Duration(days: 2)),
      lines: [
        _line(runner, size: 8, color: 'Red'),
        _line(court, size: 8, color: 'White'),
      ],
      status: OrderStatus.preparing,
      paymentMethod: 'upi',
    ),
    make(
      id: 'SF-10182',
      placedAt: now.subtract(const Duration(days: 18)),
      lines: [_line(court, size: 8, color: 'White')],
      status: OrderStatus.completed,
      paymentMethod: 'cod',
    ),
  ];
}
