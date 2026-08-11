import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";
import "../../../../orders/presentation/providers/orders_provider.dart";
import "../../../../../core/network/api_result.dart";

const _statusOptions = ["placed", "confirmed", "shipped", "out_for_delivery", "delivered", "cancelled"];

Color _statusColor(String status) => switch (status) {
      "delivered" => AppColors.success,
      "cancelled" => Colors.redAccent,
      "shipped" || "out_for_delivery" => AppColors.rust,
      "confirmed" => AppColors.olive,
      _ => AppColors.inkSoft,
    };

String _statusLabel(String status) => status
    .split("_")
    .map((w) => w.isEmpty ? w : "${w[0].toUpperCase()}${w.substring(1)}")
    .join(" ");

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> order, String status) async {
    final result = await ref.read(ordersRepositoryProvider).updateStatus(order["id"].toString(), status);
    if (!context.mounted) return;
    final message = switch (result) {
      ApiSuccess() => "Order ${order["orderNumber"]} marked ${_statusLabel(status)}",
      ApiFailure(message: final msg) => msg,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(adminOrdersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);
    return AdminShell(
      currentPath: "/admin/orders",
      title: "Orders",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ErrorView(message: "Could not load orders", onRetry: () => ref.invalidate(adminOrdersProvider)),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(child: Text("No orders yet", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
              child: LayoutBuilder(builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    final status = (o["status"] ?? "placed").toString();
                    final items = (o["items"] as List?) ?? const [];
                    final total = (o["total"] as num?) ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.receipt_long_outlined, color: AppColors.ink),
                      title: Text(o["orderNumber"]?.toString() ?? o["id"].toString(), style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        wide ? "${items.length} item(s) · ${o["paymentMethod"] ?? ""} · ${_fmtDate(o["createdAt"])}" : "${items.length} item(s) · ${_fmtDate(o["createdAt"])}",
                        style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (wide) ...[
                            Text("Rs ${total.toStringAsFixed(0)}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 16),
                          ],
                          PopupMenuButton<String>(
                            initialValue: status,
                            onSelected: (v) => _changeStatus(context, ref, o, v),
                            itemBuilder: (context) => _statusOptions
                                .map((s) => PopupMenuItem(value: s, child: Text(_statusLabel(s))))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_statusLabel(status), style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_drop_down, size: 16, color: _statusColor(status)),
                                ],
                              ),
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
    );
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return "";
    final d = DateTime.tryParse(iso.toString());
    if (d == null) return "";
    return "${d.day}/${d.month}/${d.year}";
  }
}
