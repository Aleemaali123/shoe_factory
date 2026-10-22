import 'package:flutter/material.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/shop_models.dart';

class BranchScreen extends StatelessWidget {
  const BranchScreen({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final branches = Shop.of(context).branches.branches;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a branch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Icon(Icons.storefront, size: 40, color: AppColors.deepGreen),
                const SizedBox(height: 8),
                Text(
                    branches.length == 1
                        ? 'One Shoe Factory store'
                        : '${branches.length} Shoe Factory stores',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text(
                  'Shop the same collection, or collect an order in store.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...branches.map((branch) =>
              _BranchTile(branch: branch, selected: selectedId == branch.id)),
        ],
      ),
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, required this.selected});

  final Branch branch;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: AppColors.paleGreen,
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.storefront, color: AppColors.deepGreen),
        ),
        title: Text(branch.name,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text('${branch.address}\n${branch.hours}\n${branch.phone}',
              style: const TextStyle(height: 1.45)),
        ),
        isThreeLine: true,
        trailing: Icon(selected ? Icons.check_circle : Icons.chevron_right,
            color: selected ? AppColors.deepGreen : AppColors.muted),
        onTap: () => Navigator.pop(context, branch.id),
      ),
    );
  }
}
