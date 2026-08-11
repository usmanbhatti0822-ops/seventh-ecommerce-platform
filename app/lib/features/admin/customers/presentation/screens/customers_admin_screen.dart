import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";

Color _statusColor(String status) => switch (status) {
      "blocked" => Colors.redAccent,
      "inactive" => AppColors.warning,
      _ => AppColors.success,
    };

class AdminCustomersScreen extends ConsumerWidget {
  const AdminCustomersScreen({super.key});

  void _openDetail(BuildContext context, Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.card * 3))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 28, backgroundImage: NetworkImage(c["avatar"]?.toString() ?? "")),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c["name"]?.toString() ?? "", style: displayFont(fontSize: 18)),
                      Text(c["email"]?.toString() ?? "", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                _StatusChip(status: c["status"]?.toString() ?? "active"),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.line),
            const SizedBox(height: 12),
            _DetailRow(label: "City", value: c["city"]?.toString() ?? "—"),
            _DetailRow(label: "Joined", value: c["joinedAt"]?.toString() ?? "—"),
            _DetailRow(label: "Orders", value: "${c["orderCount"] ?? 0}"),
            _DetailRow(label: "Total Spent", value: "Rs ${((c["totalSpent"] as num?) ?? 0).toStringAsFixed(0)}"),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(adminCustomersProvider);
    return AdminShell(
      currentPath: "/admin/customers",
      title: "Customers",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: customersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorView(message: "Could not load customers", onRetry: () => ref.invalidate(adminCustomersProvider)),
          data: (customers) {
            if (customers.isEmpty) {
              return Center(child: Text("No customers yet", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                return ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (context, i) {
                    final c = customers[i];
                    final orderCount = c["orderCount"] ?? 0;
                    final totalSpent = (c["totalSpent"] as num?) ?? 0;
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(c["avatar"]?.toString() ?? "")),
                      title: Text(c["name"]?.toString() ?? "", style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        wide ? "${c["email"] ?? ""} · ${c["city"] ?? ""}" : c["email"]?.toString() ?? "",
                        style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (wide) ...[
                            Text("$orderCount orders", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
                            const SizedBox(width: 16),
                            Text("Rs ${totalSpent.toStringAsFixed(0)}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 16),
                          ],
                          _StatusChip(status: c["status"]?.toString() ?? "active"),
                        ],
                      ),
                      onTap: () => _openDetail(context, c),
                    );
                  },
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(status[0].toUpperCase() + status.substring(1), style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
          Text(value, style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
