import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/payments/razorpay_checkout.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/product_image.dart';
import '../orders/order_success_screen.dart';
import '../profile/auth_screen.dart';
import '../viewmodels/shop_view_models.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  CheckoutViewModel? _model;
  final _payments = RazorpayCheckout();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _pin = TextEditingController();
  var _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_model != null) return;
    final deps = Shop.of(context);
    final model = CheckoutViewModel(
      account: deps.account,
      branches: deps.branchUseCases,
      cart: deps.cartUseCases,
      orders: deps.orderUseCases,
    );
    _name.text = model.name;
    _phone.text = model.phone;
    _model = model;
  }

  @override
  void dispose() {
    _payments.dispose();
    _model?.dispose();
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    _city.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    if (model == null) return const SizedBox.shrink();
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([model, deps.session, deps.cart]),
      builder: (context, child) {
        final quote = model.quote;
        return Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: model.items.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Nothing to check out',
                  message: 'Your cart is empty.',
                  actionLabel: 'Back to shop',
                  onAction: () => Navigator.pop(context),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _section('Order summary'),
                    const SizedBox(height: 10),
                    ...model.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: ProductImage(url: item.imageUrl)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  '${item.name}\nUK ${item.size} · ${item.color} · ×${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 12, height: 1.35)),
                            ),
                            Text(formatRupees(item.lineTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _money('Subtotal', formatRupees(quote.subtotal)),
                    if (quote.discount > 0)
                      _money('Discount', '-${formatRupees(quote.discount)}'),
                    _money(
                        'Delivery',
                        deliveryFeeLabel(quote.deliveryFee,
                            pickup: model.isPickup, subtotal: quote.subtotal)),
                    _money('Total', formatRupees(quote.total), bold: true),
                    const SizedBox(height: 22),
                    _section('1. How do you want it?'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _option(
                                model,
                                'delivery',
                                Icons.local_shipping_outlined,
                                'Home delivery',
                                'To your door')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _option(
                                model,
                                'pickup',
                                Icons.storefront_outlined,
                                'Store pickup',
                                'Free at a branch')),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _section(model.isPickup
                        ? '2. Pickup branch'
                        : '2. Delivery address'),
                    const SizedBox(height: 10),
                    if (model.isPickup)
                      RadioGroup<String>(
                        groupValue: model.pickupBranchId,
                        onChanged: (value) {
                          if (value != null) model.selectBranch(value);
                        },
                        child: Column(
                          children: [
                            for (final branch in model.branches)
                              RadioListTile<String>(
                                value: branch.id,
                                activeColor: AppColors.green,
                                contentPadding: EdgeInsets.zero,
                                title: Text(branch.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                                subtitle:
                                    Text('${branch.address}\n${branch.hours}'),
                              ),
                          ],
                        ),
                      )
                    else ...[
                      if (model.user == null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                              onPressed: () => _signIn(model),
                              child: const Text('Sign in for saved addresses')),
                        ),
                      if (model.addresses.isNotEmpty && !model.useNewAddress)
                        RadioGroup<String>(
                          groupValue: model.selectedAddressId,
                          onChanged: (value) {
                            if (value != null) model.selectAddress(value);
                          },
                          child: Column(
                            children: [
                              for (final address in model.addresses)
                                RadioListTile<String>(
                                  value: address.id,
                                  activeColor: AppColors.green,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                      '${address.label} · ${address.name}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800)),
                                  subtitle: Text(address.summary),
                                ),
                            ],
                          ),
                        ),
                      if (model.addresses.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                model.showNewAddress(!model.useNewAddress),
                            child: Text(model.useNewAddress
                                ? 'Use a saved address'
                                : 'Deliver somewhere else'),
                          ),
                        ),
                      if (model.useNewAddress || model.addresses.isEmpty) ...[
                        TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                              labelText: 'Phone number',
                              prefixIcon: Icon(Icons.phone_outlined)),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _line,
                          decoration: const InputDecoration(
                              labelText: 'House / street / landmark',
                              prefixIcon: Icon(Icons.home_outlined)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                  controller: _city,
                                  decoration:
                                      const InputDecoration(labelText: 'City')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _pin,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'PIN code'),
                              ),
                            ),
                          ],
                        ),
                        if (model.user != null)
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: model.saveAddress,
                            activeColor: AppColors.green,
                            title: const Text('Save this address'),
                            onChanged: (value) =>
                                model.toggleSave(value ?? false),
                          ),
                      ],
                    ],
                    const SizedBox(height: 12),
                    _section('3. Payment'),
                    const SizedBox(height: 4),
                    RadioGroup<String>(
                      groupValue: model.payment,
                      onChanged: (value) {
                        if (value != null) model.setPayment(value);
                      },
                      child: Column(
                        children: [
                          _pay(
                              model,
                              'razorpay',
                              Icons.account_balance_wallet_outlined,
                              'Razorpay',
                              'UPI, cards and netbanking in test mode'),
                          _pay(
                              model,
                              'cod',
                              Icons.payments_outlined,
                              'Cash on delivery',
                              model.isPickup
                                  ? 'Pay when you collect'
                                  : 'Pay when the order arrives'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (model.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(model.error!,
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700)),
                      ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.paleGreen,
                          borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        model.paysWithRazorpay
                            ? 'Razorpay test mode. Card 4111 1111 1111 1111, any future expiry and CVV, or UPI success@razorpay. No real money moves.'
                            : 'Cash is collected on delivery or at the branch. Nothing is charged now.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: model.paysWithRazorpay
                          ? 'Pay with Razorpay · ${formatRupees(quote.total)}'
                          : 'Place order · ${formatRupees(quote.total)}',
                      icon: model.paysWithRazorpay
                          ? Icons.account_balance_wallet_outlined
                          : Icons.lock_outline,
                      busy: _busy,
                      onPressed: _busy ? null : () => _place(model),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _signIn(CheckoutViewModel model) async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    if (ok == true && mounted) {
      model.adoptSignedInAddress();
      if (_name.text.isEmpty) _name.text = model.name;
      if (_phone.text.isEmpty) _phone.text = model.phone;
    }
  }

  Future<void> _place(CheckoutViewModel model) async {
    setState(() => _busy = true);
    final contact = model.resolve(
        name: _name.text,
        phone: _phone.text,
        line: _line.text,
        city: _city.text,
        pincode: _pin.text);
    if (contact == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }

    String? paymentReference;
    if (model.paysWithRazorpay) {
      final description = contact.items.length <= 1
          ? contact.items.first.name
          : '${contact.items.first.name} + ${contact.items.length - 1} more';
      try {
        paymentReference = await _payments.pay(
          amountPaise: (contact.quote.total * 100).round(),
          contact: contact.phone,
          email: model.user?.email ?? '',
          description: description,
        );
      } on RazorpayCheckoutException catch (error) {
        if (!mounted) return;
        model.note(error.message);
        setState(() => _busy = false);
        return;
      }
    }

    if (!mounted) return;
    final order =
        await model.commit(contact, paymentReference: paymentReference);
    if (!mounted) return;
    if (order == null) {
      setState(() => _busy = false);
      return;
    }
    final deps = Shop.of(context);
    deps.cart.sync();
    deps.orders.sync();
    deps.session.sync();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
            builder: (_) => OrderSuccessScreen(order: order)));
  }

  Widget _section(String text) => Text(text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900));

  Widget _money(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: bold ? 16 : 13)),
        ],
      ),
    );
  }

  Widget _option(CheckoutViewModel model, String value, IconData icon,
      String title, String subtitle) {
    final selected = model.fulfilment == value;
    return InkWell(
      onTap: () => model.setFulfilment(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.paleGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.green : AppColors.line,
              width: selected ? 1.6 : 1),
          boxShadow: selected ? AppDecor.shadow : const [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: selected ? AppColors.deepGreen : AppColors.muted),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _pay(CheckoutViewModel model, String value, IconData icon,
      String title, String subtitle) {
    final selected = model.payment == value;
    return RadioListTile<String>(
      value: value,
      activeColor: AppColors.green,
      contentPadding: EdgeInsets.zero,
      secondary:
          Icon(icon, color: selected ? AppColors.deepGreen : AppColors.muted),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    );
  }
}
