import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoe_factory/app/app.dart';
import 'package:shoe_factory/app/dependencies.dart';
import 'package:shoe_factory/core/location/device_location.dart';
import 'package:shoe_factory/core/widgets/brand_logo.dart';
import 'package:shoe_factory/core/utils/format.dart';
import 'package:shoe_factory/domain/entities/shop_models.dart';
import 'package:shoe_factory/domain/pricing/pricing.dart';
import 'package:shoe_factory/presentation/viewmodels/shop_view_models.dart';

void main() {
  test('formats rupees with Indian grouping', () {
    expect(formatRupees(999), '₹999');
    expect(formatRupees(6499), '₹6,499');
    expect(formatRupees(10998), '₹10,998');
    expect(formatRupees(100000), '₹1,00,000');
  });

  test('prices coupons, delivery and pickup', () {
    final ten =
        Pricing.calculate(subtotal: 6499, couponCode: 'TREND10', pickup: false);
    expect(ten.discount, 650);
    expect(ten.deliveryFee, 0);
    expect(ten.total, 5849);

    final plain = Pricing.calculate(subtotal: 2000, pickup: false);
    expect(plain.deliveryFee, 49);
    expect(plain.total, 2049);

    final flat =
        Pricing.evaluate(subtotal: 2000, rawCode: 'factory200', pickup: false);
    expect(flat.accepted, isTrue);
    expect(flat.quote.discount, 200);
    expect(flat.quote.total, 1849);

    final tooSmall =
        Pricing.evaluate(subtotal: 1500, rawCode: 'FACTORY200', pickup: false);
    expect(tooSmall.accepted, isFalse);

    final pickup = Pricing.calculate(subtotal: 2000, pickup: true);
    expect(pickup.deliveryFee, 0);
    expect(pickup.total, 2000);
  });

  test('cart merges variants and caps stock', () async {
    final deps = AppDependencies.create();
    final runner = deps.catalog.findById('sf001')!;
    await deps.cart.add(runner, size: 8, color: 'Red');
    await deps.cart.add(runner, size: 8, color: 'Red');
    expect(deps.cart.count, 2);
    expect(deps.cart.items, hasLength(1));

    final limited = deps.catalog.findById('sf005')!;
    await deps.cart.add(limited, size: 8, color: 'Black', quantity: 5);
    final line = deps.cart.items.last;
    expect(line.productId, 'sf005');
    expect(line.quantity, 3);
  });

  test('checkout places an order and clears the cart', () async {
    final deps = AppDependencies.create();
    final product = deps.catalog.findById('sf007')!;
    await deps.cart.add(product, size: 8, color: 'Black');
    final checkout = CheckoutViewModel(
      account: deps.account,
      branches: deps.branchUseCases,
      cart: deps.cartUseCases,
      orders: deps.orderUseCases,
    );
    final before = deps.orders.orders.length;
    final order = await checkout.place(
      name: 'Shoe Factory Shopper',
      phone: '9876543210',
      line: '12, MG Road',
      city: 'Kochi',
      pincode: '682001',
    );

    expect(order, isNotNull);
    expect(deps.cart.items, isEmpty);
    deps.orders.sync();
    expect(deps.orders.orders, hasLength(before + 1));
    expect(deps.orders.orders.first.id, order!.id);
    expect(order.total, 3048);
    expect(order.paymentMethod, 'razorpay');
  });

  test('mobile otp signs in the demo shopper and registers a new number', () async {
    final deps = AppDependencies.create();
    final missing = await deps.account.requestOtp('123');
    expect(missing.error, 'Enter a 10-digit mobile number.');

    final issued = await deps.account.requestOtp('9876543210');
    expect(issued.code, hasLength(6));
    expect(issued.registered, isTrue);
    expect(
      (await deps.account.verifyOtp(phone: '9876543210', code: '000000')).error,
      'That code does not match.',
    );
    final signedIn =
        await deps.account.verifyOtp(phone: '9876543210', code: issued.code!);
    expect(signedIn.signedIn, isTrue);
    expect(deps.session.user?.name, 'Shoe Factory Shopper');

    await deps.account.signOut();
    final fresh = await deps.account.requestOtp('9123456780');
    expect(fresh.registered, isFalse);
    final pending =
        await deps.account.verifyOtp(phone: '9123456780', code: fresh.code!);
    expect(pending.needsProfile, isTrue);
    expect(
      await deps.account.registerWithOtp(
        name: 'New Shopper',
        email: 'new@shoefactory.shop',
        phone: '9123456780',
        code: fresh.code!,
      ),
      isNull,
    );
    expect(deps.session.user?.name, 'New Shopper');
  });

  test('sign in accepts the demo account and rejects a wrong password', () async {
    final deps = AppDependencies.create();
    expect(
      await deps.account.signInWithPassword(
        email: 'shopper@shoefactory.shop',
        password: 'nope',
      ),
      'That password does not match.',
    );
    expect(
      await deps.account.signInWithPassword(
        email: 'shopper@shoefactory.shop',
        password: 'trend',
      ),
      isNull,
    );
    expect(deps.session.user?.name, 'Shoe Factory Shopper');
    expect(deps.session.addresses, isNotEmpty);

    final taken = await deps.account.register(
      name: 'Another Shopper',
      email: 'shopper@shoefactory.shop',
      phone: '9876543210',
      password: 'trend',
      confirmPassword: 'trend',
    );
    expect(taken, contains('already exists'));
  });

  testWidgets('home opens the Shoe Factory shop', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ShoeFactoryApp(
        dependencies: AppDependencies.create(
            deviceLocation: const _FixedLocation()),
        showSplash: false));
    await tester.pump();

    expect(find.byType(BrandLogo), findsOneWidget);
    expect(find.text('MG Road, Kochi'), findsOneWidget);
    expect(find.text('Trivandrum Central'), findsOneWidget);

    await tester.tap(find.text('MG Road, Kochi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Use current location'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), 'Fort Kochi');
    await tester.enterText(find.byType(TextField).at(2), 'Ernakulam');
    await tester.tap(find.text('Save location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Fort Kochi, Ernakulam'), findsOneWidget);
    expect(find.text('Shop by category'), findsOneWidget);
    expect(find.text('Air Motion Runner'), findsWidgets);

    await tester.tap(find.text('Cart'));
    await tester.pump();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });
}

class _FixedLocation implements DeviceLocation {
  const _FixedLocation();

  @override
  Future<CustomerPlace> current() async {
    return const CustomerPlace(area: 'MG Road', city: 'Kochi', fromDevice: true);
  }

  @override
  Future<void> openSettings() async {}
}
