import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_config.dart';

class RazorpayCheckoutException implements Exception {
  RazorpayCheckoutException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;
}

class RazorpayCheckout {
  Razorpay? _razorpay;
  Completer<String?>? _pending;

  Future<String?> pay({
    required int amountPaise,
    required String contact,
    required String email,
    required String description,
  }) {
    if (amountPaise < 100) {
      throw RazorpayCheckoutException('Razorpay needs an amount of at least ₹1.');
    }
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      throw RazorpayCheckoutException('A payment is already open.');
    }

    final razorpay = Razorpay();
    _razorpay = razorpay;
    final completer = Completer<String?>();
    _pending = completer;

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      _finish();
      if (!completer.isCompleted) completer.complete(response.paymentId);
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
        'key': razorpayKeyId,
        'amount': amountPaise,
        'currency': 'INR',
        'name': 'Shoe Factory',
        'description': description,
        'retry': {'enabled': true, 'max_count': 1},
        'theme': {'color': '#00C52B'},
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
