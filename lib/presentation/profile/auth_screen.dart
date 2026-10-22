import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/primary_button.dart';
import 'phone_otp_screen.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            const BrandLogo(size: 108),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Sign in to track orders, keep your addresses, and check out faster.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, height: 1.45),
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  children: [
                    _choice(
                      icon: Icons.sms_outlined,
                      title: 'Continue with mobile',
                      subtitle: 'A 6-digit code for the number on your account',
                      onTap: () => _open(context, const PhoneOtpScreen()),
                    ),
                    const SizedBox(height: 12),
                    _choice(
                      icon: Icons.login,
                      title: 'Sign in with email',
                      subtitle:
                          'Email and password for an account you already have',
                      onTap: () => _open(context, const SignInScreen()),
                    ),
                    const SizedBox(height: 12),
                    _choice(
                      icon: Icons.person_add_alt_1,
                      title: 'Create account',
                      subtitle:
                          'Name, phone and a password for a new shopper profile',
                      onTap: () => _open(context, const RegisterScreen()),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Continue with demo account',
                      icon: Icons.auto_awesome,
                      onPressed: () => _demo(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Demo mobile 9876543210. The code appears on the next screen. Email sign-in stays shopper@shoefactory.shop · trend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.muted, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => screen),
    );
    if (ok == true && context.mounted) Navigator.pop(context, true);
  }

  Future<void> _demo(BuildContext context) async {
    final error = await Shop.of(context).session.signInWithPassword(
          email: 'shopper@shoefactory.shop',
          password: 'trend',
        );
    if (error != null || !context.mounted) return;
    Navigator.pop(context, true);
  }

  Widget _choice({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.deepGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
