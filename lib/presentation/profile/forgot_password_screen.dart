import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  String? _demoCode;
  var _sending = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      kicker: 'ACCOUNT RECOVERY',
      title: 'New password',
      subtitle:
          'Request a code for the email on your Shoe Factory account, then choose a new password.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _sending ? null : _requestCode,
            child: Text(_sending ? 'Sending…' : 'Send reset code'),
          ),
          if (_demoCode != null) ...[
            const SizedBox(height: 8),
            Text('Demo code $_demoCode', textAlign: TextAlign.center),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Reset code',
              prefixIcon: Icon(Icons.sms_outlined),
            ),
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            controller: _password,
            label: 'New password',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            controller: _confirm,
            label: 'Confirm new password',
            onSubmitted: (_) => _submit(),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Update password',
            icon: Icons.lock_reset,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _requestCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    final result =
        await Shop.of(context).session.requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = result.error;
      _demoCode = result.code;
      if (result.code != null) _code.text = result.code!;
    });
  }

  Future<void> _submit() async {
    final error = await Shop.of(context).session.resetPassword(
          email: _email.text,
          code: _code.text,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }
}
