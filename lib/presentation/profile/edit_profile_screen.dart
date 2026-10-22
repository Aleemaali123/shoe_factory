import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  String? _error;
  var _filled = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final user = Shop.of(context).session.user;
    if (user == null) return;
    _name.text = user.name;
    _email.text = user.email;
    _phone.text = user.phone;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal information')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'These details are used at checkout and on your orders.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 10),
          TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 10),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(label: 'Save', onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final error = await Shop.of(context).session.updateProfile(
        name: _name.text, email: _email.text, phone: _phone.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }
}
