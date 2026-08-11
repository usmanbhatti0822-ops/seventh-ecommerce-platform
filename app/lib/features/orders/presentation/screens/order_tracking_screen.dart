import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/orders_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/error_view.dart";

const _stages = ["Placed", "Confirmed", "Shipped", "Out for Delivery", "Delivered"];

class OrderTrackingScreen extends ConsumerWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Order Details")),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: "Could not load this order", onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (order) => _OrderTrackingBody(order: order),
      ),
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTrackingBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order["status"].toString();
    final cancelled = status == "cancelled";
    final currentStage = cancelled ? -1 : _stages.indexOf(_stageFor(status));
    final items = order["items"] as List;
    final address = order["address"] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(order["orderNumber"].toString(), style: displayFont(fontSize: 22)),
            Text(cancelled ? "Cancelled" : "Rs ${(order["total"] as num).toStringAsFixed(0)}",
                style: bodyFont(fontSize: 14, fontWeight: FontWeight.w700, color: cancelled ? Colors.redAccent : AppColors.ink)),
          ],
        ),
        const SizedBox(height: 24),
        if (cancelled)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(AppRadii.card)),
            child: Row(
              children: const [
                Icon(Icons.cancel_outlined, color: Colors.redAccent),
                SizedBox(width: 10),
                Expanded(child: Text("This order was cancelled.")),
              ],
            ),
          )
        else
          for (int i = 0; i < _stages.length; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: i <= currentStage ? 1 : 0),
              duration: AppDurations.slow,
              builder: (context, value, _) => Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(AppColors.line, AppColors.ink, value),
                        ),
                        child: value > 0.5 ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      if (i != _stages.length - 1)
                        Container(width: 2, height: 40, color: AppColors.line),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Text(
                      _stages[i],
                      style: bodyFont(
                        fontSize: 14,
                        fontWeight: i <= currentStage ? FontWeight.w700 : FontWeight.w400,
                        color: i <= currentStage ? AppColors.ink : AppColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const Divider(height: 8, color: AppColors.line),
        const SizedBox(height: 16),
        Text("ITEMS", style: eyebrowFont()),
        const SizedBox(height: 12),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(2), child: Image.network(it["imageUrl"], width: 50, height: 62, fit: BoxFit.cover)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it["name"], style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600)),
                        if (it["size"] != null) Text("Size ${it["size"]} · Qty ${it["qty"]}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  Text("Rs ${((it["price"] as num) * (it["qty"] as num)).toStringAsFixed(0)}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
          child: Column(
            children: [
              _row("Subtotal", "Rs ${(order["subtotal"] as num).toStringAsFixed(0)}"),
              const SizedBox(height: 6),
              _row("Shipping", (order["shipping"] as num) == 0 ? "FREE" : "Rs ${(order["shipping"] as num).toStringAsFixed(0)}"),
              if ((order["discount"] as num) > 0) ...[
                const SizedBox(height: 6),
                _row("Discount", "-Rs ${(order["discount"] as num).toStringAsFixed(0)}"),
              ],
              const Divider(height: 20, color: AppColors.line),
              _row("Total", "Rs ${(order["total"] as num).toStringAsFixed(0)}", bold: true),
              const SizedBox(height: 6),
              _row("Payment", "${order["paymentMethod"]} · ${(order["paymentStatus"] as String).toUpperCase()}"),
            ],
          ),
        ),
        if (address != null) ...[
          const SizedBox(height: 20),
          Text("DELIVERY ADDRESS", style: eyebrowFont()),
          const SizedBox(height: 10),
          Text("${address["label"]}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
          Text("${address["line1"]}, ${address["city"]}", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          Text("${address["phone"]}", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  String _stageFor(String status) => switch (status) {
        "placed" => "Placed",
        "confirmed" => "Confirmed",
        "shipped" => "Shipped",
        "out_for_delivery" => "Out for Delivery",
        "delivered" => "Delivered",
        _ => "Placed",
      };

  Widget _row(String label, String value, {bool bold = false}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          Text(value, style: bodyFont(fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
        ],
      );
}
