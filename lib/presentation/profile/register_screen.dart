import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthChrome(
      kicker: 'JOIN SHOE FACTORY',
      title: 'Create account',
      subtitle:
          'Your profile stays on this device. A home address is saved so checkout is ready.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            controller: _password,
            label: 'Password',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AuthPasswordField(
            controller: _confirm,
            label: 'Confirm password',
            onSubmitted: (_) => _submit(),
          ),
          AuthErrorText(_error),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Create account',
            icon: Icons.person_add_alt_1,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already shopping here?',
                  style: TextStyle(color: AppColors.muted)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final error = await Shop.of(context).session.register(
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
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
