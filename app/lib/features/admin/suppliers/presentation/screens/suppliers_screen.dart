import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";

Color _statusColor(String status) => switch (status) {
      "active" => AppColors.success,
      "paused" => AppColors.warning,
      _ => Colors.redAccent,
    };

class AdminSuppliersScreen extends ConsumerWidget {
  const AdminSuppliersScreen({super.key});

  void _addSupplier(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final feedCtrl = TextEditingController(text: "API");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Supplier", style: displayFont(fontSize: 18)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Supplier name", border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: feedCtrl, decoration: const InputDecoration(labelText: "Feed type (API / CSV / Manual)", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final name = nameCtrl.text.trim().isEmpty ? "New Supplier" : nameCtrl.text.trim();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supplier "$name" invited to onboard')));
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(adminSuppliersProvider);
    return AdminShell(
      currentPath: "/admin/suppliers",
      title: "Suppliers",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(onPressed: () => _addSupplier(context, ref), icon: const Icon(Icons.add), label: const Text("Add Supplier")),
            const SizedBox(height: 16),
            Expanded(
              child: suppliersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(message: "Could not load suppliers", onRetry: () => ref.invalidate(adminSuppliersProvider)),
                data: (suppliers) {
                  if (suppliers.isEmpty) {
                    return Center(child: Text("No suppliers yet", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
                  }
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      return ListView.separated(
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, i) {
                          final s = suppliers[i];
                          final status = s["status"]?.toString() ?? "active";
                          final lastSync = DateTime.tryParse(s["lastSync"]?.toString() ?? "");
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: AppColors.ink.withOpacity(0.08), child: const Icon(Icons.local_shipping_outlined, color: AppColors.ink)),
                            title: Text(s["name"]?.toString() ?? "", style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              wide
                                  ? "Feed: ${s["feedType"]} · ${s["productsSupplied"]} SKUs · ${s["fulfillmentRate"]}% on-time · ${s["avgDeliveryDays"]}d avg delivery"
                                  : "Feed: ${s["feedType"]} · ${s["fulfillmentRate"]}% on-time",
                              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (wide && lastSync != null) ...[
                                  Text("Synced ${_fmtAgo(lastSync)}", style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft)),
                                  const SizedBox(width: 12),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
