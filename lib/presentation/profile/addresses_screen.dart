import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/entities/shop_models.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Shop.of(context).session;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved addresses')),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, child) {
          final addresses = session.addresses;
          if (addresses.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses',
              message: 'Add one for faster checkout.',
              actionLabel: 'Add address',
              onAction: () => _openEditor(context),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...addresses.map((address) => _AddressTile(address: address)),
              const SizedBox(height: 8),
              PrimaryButton(
                  label: 'Add address',
                  icon: Icons.add,
                  onPressed: () => _openEditor(context)),
            ],
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, {Address? address}) {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => AddressEditorScreen(existing: address)));
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context) {
    final session = Shop.of(context).session;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(address.label,
                        style: const TextStyle(fontWeight: FontWeight.w900))),
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Default',
                        style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(address.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(address.summary,
                style: const TextStyle(color: AppColors.muted, height: 1.4)),
            Text(address.phone, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => AddressEditorScreen(existing: address)),
                  ),
                  child: const Text('Edit'),
                ),
                if (!address.isDefault)
                  TextButton(
                      onPressed: () => session.setDefaultAddress(address.id),
                      child: const Text('Make default')),
                TextButton(
                  onPressed: () => session.deleteAddress(address.id),
                  child: const Text('Delete',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddressEditorScreen extends StatefulWidget {
  const AddressEditorScreen({super.key, this.existing});

  final Address? existing;

  @override
  State<AddressEditorScreen> createState() => _AddressEditorScreenState();
}

class _AddressEditorScreenState extends State<AddressEditorScreen> {
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _city;
  late final TextEditingController _pin;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? 'Home');
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _line = TextEditingController(text: existing?.line ?? '');
    _city = TextEditingController(text: existing?.city ?? '');
    _pin = TextEditingController(text: existing?.pincode ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    _city.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.existing == null ? 'Add address' : 'Edit address')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label')),
          const SizedBox(height: 10),
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Recipient name')),
          const SizedBox(height: 10),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 10),
          TextField(
              controller: _line,
              decoration: const InputDecoration(labelText: 'House / street')),
          const SizedBox(height: 10),
          TextField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City')),
          const SizedBox(height: 10),
          TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN code')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(label: 'Save address', onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final error = await Shop.of(context).session.saveAddress(
          id: widget.existing?.id,
          label: _label.text,
          name: _name.text,
          phone: _phone.text,
          line: _line.text,
          city: _city.text,
          pincode: _pin.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context);
  }
}
