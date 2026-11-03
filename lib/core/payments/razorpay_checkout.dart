import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../utils/format.dart';
import 'razorpay_config.dart';

class RazorpayCheckoutException implements Exception {
  RazorpayCheckoutException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;
}

class RazorpayPaymentResult {
  const RazorpayPaymentResult({
    required this.paymentId,
    this.orderId,
    this.signature,
  });

  final String paymentId;
  final String? orderId;
  final String? signature;
}

class RazorpayCheckout {
  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _pending;

  Future<RazorpayPaymentResult> pay({
    required int amountPaise,
    required String contact,
    required String email,
    required String description,
    String? keyId,
    String? orderId,
    BuildContext? context,
  }) async {
    if (amountPaise < 100) {
      throw RazorpayCheckoutException('Razorpay needs an amount of at least ₹1.');
    }
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      throw RazorpayCheckoutException('A payment is already open.');
    }

    final resolvedKey = (keyId ?? razorpayKeyId).trim();
    if (resolvedKey.isEmpty || resolvedKey == 'rzp_test_1DP5mmOlF5G5ag') {
      return _payWithDemo(
        amountPaise: amountPaise,
        description: description,
        context: context,
      );
    }

    final resolvedOrderId = orderId?.trim();
    try {
      return await _payWithRazorpay(
        amountPaise: amountPaise,
        contact: contact,
        email: email,
        description: description,
        keyId: resolvedKey,
        orderId: resolvedOrderId,
      );
    } on RazorpayCheckoutException catch (error) {
      // Only fall back to local demo when the backend did not open a real order.
      if (resolvedOrderId == null || resolvedOrderId.isEmpty) {
        if (_isMissingMethods(error.message) &&
            context != null &&
            context.mounted) {
          return _payWithDemo(
            amountPaise: amountPaise,
            description: description,
            context: context,
          );
        }
      }
      rethrow;
    }
  }

  Future<RazorpayPaymentResult> _payWithDemo({
    required int amountPaise,
    required String description,
    BuildContext? context,
  }) async {
    if (context == null || !context.mounted) {
      throw RazorpayCheckoutException(
        'Demo online payment needs the checkout screen. Try again.',
      );
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Demo online payment'),
          content: Text(
            '$description\n\nAmount: ${formatRupees(amountPaise / 100)}\n\n'
            'No money is charged. Continue to place the order?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Pay now'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      throw RazorpayCheckoutException('Payment was cancelled.', cancelled: true);
    }
    return RazorpayPaymentResult(
      paymentId: 'pay_demo_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
    );
  }

  Future<RazorpayPaymentResult> _payWithRazorpay({
    required int amountPaise,
    required String contact,
    required String email,
    required String description,
    required String keyId,
    String? orderId,
  }) {
    final razorpay = Razorpay();
    _razorpay = razorpay;
    final completer = Completer<RazorpayPaymentResult>();
    _pending = completer;

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      _finish();
      final paymentId = response.paymentId?.trim() ?? '';
      if (paymentId.isEmpty) {
        if (!completer.isCompleted) {
          completer.completeError(
            RazorpayCheckoutException('Razorpay did not confirm the payment.'),
          );
        }
        return;
      }
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayPaymentResult(
            paymentId: paymentId,
            orderId: response.orderId,
            signature: response.signature,
          ),
        );
      }
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      _finish();
      if (!completer.isCompleted) {
        completer.completeError(
          RazorpayCheckoutException(
            _failureMessage(response),
            cancelled: response.code == Razorpay.PAYMENT_CANCELLED,
          ),
        );
      }
    });
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      _finish();
      if (!completer.isCompleted) {
        completer.completeError(
          RazorpayCheckoutException(
            'Pay with UPI or a card in Razorpay to place this order.',
          ),
        );
      }
    });

    final digits = contact.replaceAll(RegExp(r'\D'), '');
    final phone = digits.length >= 10 ? digits.substring(digits.length - 10) : '';
    final prefill = <String, String>{
      if (phone.length == 10) 'contact': phone,
      if (email.contains('@')) 'email': email.trim(),
    };

    try {
      razorpay.open({
        'key': keyId,
        'amount': amountPaise,
        'currency': 'INR',
        'name': 'Shoe Factory',
        'description': description,
        'retry': {'enabled': true, 'max_count': 1},
        'theme': {'color': '#00C52B'},
        if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
        if (prefill.isNotEmpty) 'prefill': prefill,
      });
    } on MissingPluginException {
      _finish();
      if (!completer.isCompleted) {
        completer.completeError(
          RazorpayCheckoutException('Razorpay checkout runs on the Android app.'),
        );
      }
    } catch (_) {
      _finish();
      if (!completer.isCompleted) {
        completer.completeError(
          RazorpayCheckoutException('Could not open Razorpay. Try again.'),
        );
      }
    }
    return completer.future;
  }

  void _finish() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void dispose() {
    _finish();
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        RazorpayCheckoutException('Payment was cancelled.', cancelled: true),
      );
    }
  }
}

bool _isMissingMethods(String message) {
  return message.toLowerCase().contains('no appropriate payment method');
}

String _failureMessage(PaymentFailureResponse response) {
  if (response.code == Razorpay.PAYMENT_CANCELLED) {
    return 'Payment was cancelled.';
  }
  final nested = response.error;
  if (nested != null) {
    final fromMap = _descriptionOf(nested);
    if (fromMap != null) return fromMap;
  }
  final raw = response.message?.trim() ?? '';
  if (raw.startsWith('{')) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final fromJson = _descriptionOf(decoded);
        if (fromJson != null) return fromJson;
      }
    } catch (_) {}
  }
  if (raw.isEmpty || raw == 'undefined') {
    return 'Razorpay could not take the payment. Try again.';
  }
  return raw;
}

String? _descriptionOf(Map<dynamic, dynamic> body) {
  final error = body['error'];
  if (error is Map && error['description'] is String) {
    final description = (error['description'] as String).trim();
    if (description.isNotEmpty) return description;
  }
  final description = body['description'];
  if (description is String && description.trim().isNotEmpty) {
    return description.trim();
  }
  return null;
}
