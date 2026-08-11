import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../core/theme/app_theme.dart" show AppColors, displayFont, bodyFont;
import "admin/auth/admin_role_provider.dart";

/// Shared responsive shell (sidebar + topbar) for every Admin Web Panel screen.
/// Menu items are filtered against [roleMenuAccess] so each role only sees
/// (and can navigate to) sections the backend RBAC guard actually permits.
///
/// [currentPath] is the route this screen was built for (e.g. "/admin/products")
/// — the active sidebar/bottomnav item is derived from it directly instead of
/// a positional index, so adding/reordering menu items never desyncs it.
class AdminShell extends ConsumerWidget {
  final String currentPath;
  final String title;
  final Widget child;
  const AdminShell({super.key, required this.currentPath, required this.title, required this.child});

  static const _items = [
    ("Dashboard", Icons.dashboard_outlined, "/admin"),
    ("Products", Icons.inventory_2_outlined, "/admin/products"),
    ("Inventory", Icons.warehouse_outlined, "/admin/inventory"),
    ("Suppliers", Icons.local_shipping_outlined, "/admin/suppliers"),
    ("Orders", Icons.receipt_long_outlined, "/admin/orders"),
    ("Promotions", Icons.local_offer_outlined, "/admin/promotions"),
    ("Customers", Icons.people_outline, "/admin/customers"),
    ("Staff", Icons.badge_outlined, "/admin/staff"),
    ("Reports", Icons.bar_chart_outlined, "/admin/reports"),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(adminRoleProvider);
    final allowed = roleMenuAccess[role] ?? [];
    final visibleItems = _items.where((it) => allowed.contains(it.$1)).toList();
    final wide = MediaQuery.of(context).size.width > 900;
    final selectedInVisible = visibleItems.indexWhere((it) => it.$3 == currentPath);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Row(
        children: [
          if (wide)
            Container(
              width: 240,
              color: AppColors.woodDeep,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Text("SEVENTH", style: displayFont(fontSize: 20, color: AppColors.paper, letterSpacing: 1.2)),
                  ),
                  for (final item in visibleItems)
                    _NavTile(
                      icon: item.$2,
                      label: item.$1,
                      selected: item.$3 == currentPath,
                      onTap: () => context.go(item.$3),
                    ),
                ],
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  color: Colors.white,
                  width: double.infinity,
                  child: Row(
                    children: [
                      Text(title, style: displayFont(fontSize: 22)),
                      const Spacer(),
                      CircleAvatar(radius: 16, backgroundColor: AppColors.ink, child: Text(_roleInitial(role), style: bodyFont(fontSize: 12, color: AppColors.paper, fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selectedInVisible < 0 ? 0 : selectedInVisible,
              onDestinationSelected: (i) => context.go(visibleItems[i].$3),
              destinations: [
                for (final it in visibleItems) NavigationDestination(icon: Icon(it.$2), label: it.$1),
              ],
            ),
    );
  }

  String _roleInitial(AdminRole role) => switch (role) {
        AdminRole.owner => "O",
        AdminRole.manager => "M",
        AdminRole.support => "S",
        AdminRole.catalogEditor => "C",
      };
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.paper.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: selected ? AppColors.olive : Colors.transparent, width: 2.5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.paper : AppColors.paper.withOpacity(0.55)),
            const SizedBox(width: 12),
            Text(label, style: bodyFont(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.paper : AppColors.paper.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}
