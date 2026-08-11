import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../auth/presentation/providers/auth_provider.dart";
import "../../../orders/presentation/providers/orders_provider.dart";
import "../../../wishlist/presentation/providers/wishlist_provider.dart";

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final wishlist = ref.watch(wishlistProvider);
    final orderCount = ordersAsync.maybeWhen(data: (o) => o.length, orElse: () => 0);

    final tiles = [
      ("Order History", Icons.receipt_long_outlined, () => context.push("/orders")),
      ("Wishlist", Icons.favorite_border, () => context.push("/wishlist")),
      ("Offers & Coupons", Icons.local_offer_outlined, () => context.push("/coupons")),
      ("Notifications", Icons.notifications_none, () => context.push("/notifications")),
      ("Addresses", Icons.location_on_outlined, () => _showComingSoon(context, "Address book")),
      ("Payment Methods", Icons.credit_card_outlined, () => _showComingSoon(context, "Saved payment methods")),
      ("Support & Chat", Icons.support_agent_outlined, () => _showComingSoon(context, "Live support")),
      ("Settings", Icons.settings_outlined, () => _showComingSoon(context, "Settings")),
    ];

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 34, backgroundColor: AppColors.ink, child: Icon(Icons.person, color: Colors.white, size: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Usman Tariq", style: displayFont(fontSize: 20)),
                    const SizedBox(height: 3),
                    Text("usman@example.com", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _statCard("$orderCount", "Orders")),
              const SizedBox(width: 12),
              Expanded(child: _statCard("${wishlist.products.length}", "Wishlist")),
              const SizedBox(width: 12),
              Expanded(child: _statCard("Vol. 07", "Member Since")),
            ],
          ),
          const SizedBox(height: 24),
          ...tiles.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: t.$3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(t.$2, color: AppColors.ink),
                      title: Text(t.$1, style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.inkSoft),
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).logout();
                ref.invalidate(isLoggedInProvider);
                if (context.mounted) context.go("/login");
              },
              child: const Text("LOG OUT"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: Column(
          children: [
            Text(value, style: displayFont(fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft)),
          ],
        ),
      );

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature — coming in a future phase")),
    );
  }
}
