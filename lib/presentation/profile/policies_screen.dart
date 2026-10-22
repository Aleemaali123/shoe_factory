import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const sections = [
      (
        'Returns',
        'Unworn shoes in original packaging can be returned within 7 days. Sale items can be exchanged for size, subject to stock.'
      ),
      (
        'Shipping',
        'Delivery is ₹49, and free when the cart is ₹4,999 or more. Store pickup is always free. Most Kerala orders arrive in 2–4 days.'
      ),
      (
        'Privacy',
        'Your name, phone and address stay on this device in this demo. A production store would keep them in your account and use them only to fulfil orders.'
      ),
      (
        'Terms',
        'Prices are in Indian rupees and include the discounts shown on each pair. Online payment uses Razorpay test mode, so a successful demo payment is not a real charge or a binding sale.'
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Policies')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in sections)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(section.$2,
                      style: const TextStyle(
                          color: AppColors.muted, height: 1.45)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
