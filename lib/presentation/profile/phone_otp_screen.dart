import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_widgets.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _issuedCode;
  var _needsProfile = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      kicker: 'MOBILE SIGN IN',
      title: _needsProfile ? 'Your details' : 'Mobile number',
      subtitle: _needsProfile
          ? 'This number is new. Add your name and email to finish the account.'
          : 'We check a 6-digit code on this device. No SMS leaves the phone.',
      child: _needsProfile ? _profileForm() : _otpForm(),
    );
  }

  Widget _otpForm() {
    final sent = _issuedCode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          maxLength: 10,
          enabled: !sent,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: const InputDecoration(
            labelText: 'Mobile number',
            prefixText: '+91 ',
            counterText: '',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        if (sent) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _verify(),
            decoration: const InputDecoration(
              labelText: '6-digit code',
              counterText: '',
              prefixIcon: Icon(Icons.sms_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Demo code $_issuedCode. It expires in 5 minutes.',
              style: const TextStyle(
                  color: AppColors.deepGreen, fontWeight: FontWeight.w800),
            ),
          ),
        ],
        AuthErrorText(_error),
        const SizedBox(height: 16),
        PrimaryButton(
          label: sent ? 'Verify and continue' : 'Send code',
          icon: sent ? Icons.verified_outlined : Icons.sms_outlined,
          onPressed: sent ? _verify : _send,
        ),
        if (sent) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() {
              _issuedCode = null;
              _code.clear();
              _error = null;
            }),
            child: const Text('Use a different number'),
          ),
          TextButton(onPressed: _send, child: const Text('Resend code')),
        ],
        const SizedBox(height: 8),
        const Text(
          'Demo shopper: 9876543210',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _profileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '+91 ${_phone.text}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Full name',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _finishProfile(),
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        AuthErrorText(_error),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Create account',
          icon: Icons.person_add_alt_1,
          onPressed: _finishProfile,
        ),
      ],
    );
  }

  Future<void> _send() async {
    final issued = await Shop.of(context).session.requestOtp(_phone.text);
    if (!mounted) return;
    setState(() {
      _error = issued.error;
      _issuedCode = issued.error == null ? issued.code : null;
      if (issued.error == null) _code.clear();
    });
  }

  Future<void> _verify() async {
    final result = await Shop.of(context).session.verifyOtp(
          phone: _phone.text,
          code: _code.text,
        );
    if (!mounted) return;
    if (result.needsProfile) {
      setState(() {
        _needsProfile = true;
        _error = null;
      });
      return;
    }
    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }
    Navigator.pop(context, true);
  }

  Future<void> _finishProfile() async {
    final error = await Shop.of(context).session.registerWithOtp(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          code: _code.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }
}
