import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shop_context.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand_logo.dart';
import '../../domain/entities/shop_models.dart';
import '../branches/branch_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/shopping_history_screen.dart';
import '../viewmodels/shop_view_models.dart';
import '../wishlist/wishlist_screen.dart';
import 'addresses_screen.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'phone_otp_screen.dart';
import 'policies_screen.dart';
import 'register_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = Shop.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
          deps.session,
          deps.orders,
          deps.wishlist,
          deps.cart,
          deps.branches,
          deps.notices,
        ]),
      builder: (context, child) {
        final user = deps.session.user;
        final orders = deps.orders.orders;
        final pairs = orders
            .where((order) => order.status != OrderStatus.cancelled)
            .fold<int>(0, (sum, order) => sum + order.itemCount);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: ColoredBox(
            color: AppColors.canvas,
            child: Column(
              children: [
                DecoratedBox(
                  decoration: AppDecor.header,
                  child: _Header(user: user),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      Row(
                        children: [
                          _stat('Orders', '${orders.length}',
                              () => deps.shell.select(ShopTab.orders)),
                          const SizedBox(width: 8),
                          _stat('Pairs', '$pairs',
                              () => deps.shell.select(ShopTab.orders)),
                          const SizedBox(width: 8),
                          _stat('Wishlist', '${deps.wishlist.count}',
                              () => _push(context, const WishlistScreen())),
                          const SizedBox(width: 8),
                          _stat('Cart', '${deps.cart.count}',
                              () => deps.shell.select(ShopTab.cart)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ShoppingHistorySection(orders: orders),
                      const SizedBox(height: 18),
                      _section(
                        'Account',
                        [
                          _tile(
                            Icons.badge_outlined,
                            'Personal information',
                            user == null
                                ? 'Sign in to save your details'
                                : '${user.email} · ${user.phone}',
                            () => _openAccount(context, signedIn: user != null),
                          ),
                          _tile(
                            Icons.location_on_outlined,
                            'Saved addresses',
                            user == null
                                ? 'Sign in to keep delivery locations'
                                : '${deps.session.addresses.length} saved',
                            () {
                              if (user == null) {
                                _push(context, const AuthScreen());
                              } else {
                                _push(context, const AddressesScreen());
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _section(
                        'Shopping',
                        [
                          _tile(
                            Icons.history,
                            'Shopping history',
                            orders.isEmpty
                                ? 'Pairs you buy show up here'
                                : '${shoppingHistory(orders).length} purchased',
                            () => openShoppingHistory(context),
                          ),
                          _tile(
                            Icons.local_shipping_outlined,
                            'My orders',
                            orders.isEmpty
                                ? 'Nothing placed yet'
                                : '${orders.length} on this device',
                            () => deps.shell.select(ShopTab.orders),
                          ),
                          _tile(
                            Icons.favorite_border,
                            'Wishlist',
                            deps.wishlist.count == 0
                                ? 'Pairs you save show up here'
                                : '${deps.wishlist.count} saved',
                            () => _push(context, const WishlistScreen()),
                          ),
                          _tile(
                            Icons.notifications_none,
                            'Notifications',
                            deps.notices.unread == 0
                                ? 'Offers and order updates'
                                : '${deps.notices.unread} unread',
                            () => _push(context, const NotificationsScreen()),
                          ),
                          _tile(
                            Icons.storefront_outlined,
                            'Find a branch',
                            deps.branches.selected.name,
                            () async {
                              final id = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BranchScreen(
                                      selectedId: deps.branches.selected.id),
                                ),
                              );
                              if (id != null) deps.branches.select(id);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _section(
                        'Support',
                        [
                          _tile(
                            Icons.support_agent,
                            'Help & support',
                            'Delivery, returns and coupons',
                            () => _push(context, const HelpScreen()),
                          ),
                          _tile(
                            Icons.policy_outlined,
                            'Policies',
                            'Returns, shipping and privacy',
                            () => _push(context, const PoliciesScreen()),
                          ),
                        ],
                      ),
                      if (user != null) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _signOut(context),
                            icon: const Icon(Icons.logout,
                                color: AppColors.danger),
                            label: const Text('Sign out',
                                style: TextStyle(color: AppColors.danger)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.danger),
                              foregroundColor: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Shoe Factory · Trend Setters',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Your cart and orders stay on this device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay signed in')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      await Shop.of(context).session.signOut();
    }
  }

  void _openAccount(BuildContext context, {required bool signedIn}) {
    _push(context, signedIn ? const EditProfileScreen() : const AuthScreen());
  }

  Future<void> _push(BuildContext context, Widget screen) {
    return Navigator.push(
        context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  Widget _stat(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x22151715),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(value,
                      key: ValueKey('$label-$value'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 18)),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: const Color(0x22151715),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: AppColors.muted,
                    letterSpacing: .4)),
          ),
          ...tiles,
        ],
      ),
    );
  }

  Widget _tile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: AppColors.paleGreen,
            borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.deepGreen),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final UserAccount? user;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        child: user == null ? _signedOut(context) : _signedIn(context, user!),
      ),
    );
  }

  Widget _signedOut(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            BrandLogo(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY PROFILE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Welcome to Shoe Factory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Sign in to save addresses and check out faster. Orders on this device stay visible either way.',
          style: TextStyle(color: Colors.white70, height: 1.35, fontSize: 13),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const PhoneOtpScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.deepGreen,
                  minimumSize: const Size(48, 46),
                ),
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const RegisterScreen()),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(48, 46),
                ),
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _signedIn(BuildContext context, UserAccount user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.white,
          child: Text(
            _initials(user.name),
            style: const TextStyle(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TREND SETTERS MEMBER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(user.email,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              const SizedBox(height: 2),
              Text(user.phone,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()),
          ),
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          tooltip: 'Edit profile',
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'SF';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
