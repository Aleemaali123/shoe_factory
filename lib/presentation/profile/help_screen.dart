import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/pricing/pricing.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coupons = Pricing.coupons;
    final couponAnswer = coupons.isEmpty
        ? 'There are no coupon codes right now.'
        : coupons.map((coupon) => '${coupon.code}: ${coupon.label}').join(' ');
    final faqs = [
      (
        'How long does delivery take?',
        'Home delivery in Kerala usually arrives in 2–4 days. Store pickup is ready in 1–2 days.'
      ),
      (
        'Can I collect from a branch?',
        'Yes. Choose store pickup at checkout and we will mark the order ready for collection.'
      ),
      (
        'How do returns work?',
        'Unworn shoes can be returned within 7 days of delivery or collection, with the original packaging.'
      ),
      (
        'Which coupon codes work?',
        couponAnswer
      ),
      (
        'Is payment live?',
        'Pay online opens Razorpay in test mode. Use card 4111 1111 1111 1111 or UPI success@razorpay. Cash on delivery is still collected later. No real money moves.'
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(18)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('We are here to help',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
                SizedBox(height: 6),
                Text('hello@shoefactory.shop',
                    style: TextStyle(color: Colors.white)),
                Text('0471 555 0100 · 10:00 AM–9:00 PM',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: ExpansionTile(
                title: Text(faq.$1,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child:
                            Text(faq.$2, style: const TextStyle(height: 1.4))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
