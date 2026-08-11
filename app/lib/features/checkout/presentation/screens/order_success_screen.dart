import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "../../../../core/theme/app_theme.dart";

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: AppDurations.slow,
                curve: Curves.elasticOut,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              ),
              const SizedBox(height: 28),
              Text("Order Placed", style: displayFont(fontSize: 30), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                "Your order ${order["orderNumber"]} has been confirmed.\nWe'll notify you as it moves.",
                textAlign: TextAlign.center,
                style: bodyFont(fontSize: 14, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
                child: Column(
                  children: [
                    _row("Order Number", order["orderNumber"].toString()),
                    const SizedBox(height: 8),
                    _row("Payment Method", order["paymentMethod"].toString()),
                    const SizedBox(height: 8),
                    _row("Total Paid", "Rs ${(order["total"] as num).toStringAsFixed(0)}"),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go("/order/${order["id"]}"),
                  child: const Text("TRACK ORDER"),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go("/"),
                  child: const Text("CONTINUE SHOPPING"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          Text(value, style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      );
}
