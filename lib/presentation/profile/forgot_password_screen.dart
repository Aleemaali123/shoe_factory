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
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
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
          'Choose a new password for the email on your Shoe Factory account.',
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

  Future<void> _submit() async {
    final error = await Shop.of(context).session.resetPassword(
          email: _email.text,
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
