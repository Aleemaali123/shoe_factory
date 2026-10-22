import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../domain/entities/shop_models.dart';
import '../viewmodels/shop_view_models.dart';

Future<void> changeCustomerLocation(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const LocationSheet(),
  );
}

class LocationSheet extends StatefulWidget {
  const LocationSheet({super.key});

  @override
  State<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<LocationSheet> {
  final _area = TextEditingController();
  final _city = TextEditingController();
  String? _formError;
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final place = Shop.of(context).location.place;
    _area.text = place?.area ?? '';
    _city.text = place?.city ?? '';
  }

  @override
  void dispose() {
    _area.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = Shop.of(context).location;
    final addresses = Shop.of(context).session.addresses;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return ListenableBuilder(
      listenable: location,
      builder: (context, child) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Your location',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                  'We use this to show where you are shopping from.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: location.loading ? null : () => _detect(location),
                  icon: location.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(location.loading
                      ? 'Finding your location…'
                      : 'Use current location'),
                ),
                if (location.error != null) ...[
                  const SizedBox(height: 10),
                  Text(location.error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                  if (location.canOpenSettings)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: location.openSettings,
                        child: const Text('Open settings'),
                      ),
                    ),
                ],
                if (addresses.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text('Saved addresses',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...addresses.map(
                    (address) => _SavedAddressTile(
                      address: address,
                      onTap: () {
                        location.setManual(
                            area: address.line, city: address.city);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text('Enter it yourself',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                TextField(
                  controller: _area,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Area or street',
                    hintText: 'MG Road',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    hintText: 'Kochi',
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 8),
                  Text(_formError!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Save location',
                  icon: Icons.check,
                  onPressed: () => _save(location),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _detect(LocationViewModel location) async {
    setState(() => _formError = null);
    await location.detect();
    if (!mounted || location.error != null || location.place == null) return;
    Navigator.pop(context);
  }

  void _save(LocationViewModel location) {
    final area = _area.text.trim();
    final city = _city.text.trim();
    if (area.isEmpty && city.isEmpty) {
      setState(() => _formError = 'Enter an area or a city.');
      return;
    }
    location.setManual(area: area, city: city);
    Navigator.pop(context);
  }
}

class _SavedAddressTile extends StatelessWidget {
  const _SavedAddressTile({required this.address, required this.onTap});

  final Address address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.bookmark_outline, color: AppColors.deepGreen),
        title: Text(address.label,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(address.summary),
        onTap: onTap,
      ),
    );
  }
}
