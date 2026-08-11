import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/orders_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/error_view.dart";

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("My Orders")),
      body: ordersAsync.when(
        loading: () => const _OrdersShimmer(),
        error: (err, _) => ErrorView(message: "Could not load orders", onRetry: () => ref.invalidate(myOrdersProvider)),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyView(message: "No orders yet", icon: Icons.receipt_long_outlined),
                  const SizedBox(height: 16),
                  OutlinedButton(onPressed: () => context.go("/"), child: const Text("START SHOPPING")),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myOrdersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final order = orders[i] as Map<String, dynamic>;
                final items = order["items"] as List;
                final status = order["status"].toString();
                return InkWell(
                  onTap: () => context.push("/order/${order["id"]}"),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(order["orderNumber"].toString(), style: bodyFont(fontSize: 14, fontWeight: FontWeight.w700)),
                            _StatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(order["createdAt"].toString()),
                          style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: Row(
                            children: [
                              ...items.take(4).map((it) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Image.network(it["imageUrl"], width: 44, height: 54, fit: BoxFit.cover),
                                    ),
                                  )),
                              if (items.length > 4)
                                Container(
                                  width: 44,
                                  height: 54,
                                  alignment: Alignment.center,
                                  color: AppColors.paper,
                                  child: Text("+${items.length - 4}", style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${items.length} item${items.length == 1 ? "" : "s"}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                            Text("Rs ${(order["total"] as num).toStringAsFixed(0)}", style: displayFont(fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return "${months[d.month - 1]} ${d.day}, ${d.year}";
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color => switch (status) {
        "delivered" => AppColors.success,
        "cancelled" => Colors.redAccent,
        "shipped" || "confirmed" => AppColors.rust,
        _ => AppColors.inkSoft,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.chip)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}

class _OrdersShimmer extends StatelessWidget {
  const _OrdersShimmer();
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
      ),
    );
  }
}
