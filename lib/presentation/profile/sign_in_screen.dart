import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/shop_messenger.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'phone_otp_screen.dart';
import 'register_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      kicker: 'WELCOME BACK',
      title: 'Sign in',
      subtitle: 'Use the email and password for your Shoe Factory account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            controller: _password,
            label: 'Password',
            onSubmitted: (_) => _submit(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                      builder: (_) => const ForgotPasswordScreen()),
                );
                if (updated == true && context.mounted) {
                  showShopMessage(
                      context, 'Password updated. Sign in with the new one.');
                }
              },
              child: const Text('Forgot password?'),
            ),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 8),
          PrimaryButton(
              label: 'Sign in', icon: Icons.login, onPressed: _submit),
          TextButton(
            onPressed: () async {
              final ok = await Navigator.push<bool>(
                context,
                MaterialPageRoute<bool>(builder: (_) => const PhoneOtpScreen()),
              );
              if (ok == true && context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Sign in with mobile code'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _fillDemo,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Fill the demo account'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('New here?', style: TextStyle(color: AppColors.muted)),
              TextButton(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute<bool>(
                        builder: (_) => const RegisterScreen()),
                  );
                  if (created == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _fillDemo() {
    setState(() {
      _email.text = 'shopper@shoefactory.shop';
      _password.text = 'trend';
      _error = null;
    });
  }

  Future<void> _submit() async {
    final error = await Shop.of(context).session.signInWithPassword(
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, true);
  }
}
