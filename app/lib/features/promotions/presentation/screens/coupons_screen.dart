import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/promotions_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/error_view.dart";

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Offers & Coupons")),
      body: couponsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            height: 96,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
          ),
        ),
        error: (err, _) => ErrorView(message: "Could not load offers", onRetry: () => ref.invalidate(couponsProvider)),
        data: (coupons) {
          if (coupons.isEmpty) return const EmptyView(message: "No active offers right now", icon: Icons.local_offer_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, i) {
              final c = coupons[i];
              final validUntil = DateTime.tryParse(c["validUntil"].toString());
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(AppRadii.card)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c["discountLabel"], style: displayFont(fontSize: 18, color: AppColors.paper)),
                            const SizedBox(height: 4),
                            Text(c["description"], style: bodyFont(fontSize: 12, color: AppColors.paper.withOpacity(0.7))),
                            const SizedBox(height: 4),
                            if (validUntil != null)
                              Text(
                                "Valid until ${validUntil.day}/${validUntil.month}/${validUntil.year} · ${c["usageCount"]} used",
                                style: bodyFont(fontSize: 10.5, color: AppColors.paper.withOpacity(0.5)),
                              ),
                            const SizedBox(height: 10),
                            DottedCodeChip(code: c["code"]),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Copied ${c["code"]}")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DottedCodeChip extends StatelessWidget {
  final String code;
  const DottedCodeChip({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(code, style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
    );
  }
}
