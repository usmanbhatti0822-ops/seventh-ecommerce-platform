import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../promotions/presentation/providers/promotions_provider.dart";

class AdminPromotionsScreen extends ConsumerWidget {
  const AdminPromotionsScreen({super.key});

  /// There's no create-coupon/flash-sale/banner mutation route on the mock
  /// backend yet (promotions is read-only there) — these actions collect
  /// input and confirm via snackbar rather than silently doing nothing.
  void _quickAction(BuildContext context, String title, String confirmMessage, List<Widget> Function(void Function(void Function()) setState, Map<String, String> values) fields) {
    final values = <String, String>{};
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title, style: displayFont(fontSize: 18)),
          content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: fields(setState, values))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(confirmMessage)));
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _newCoupon(BuildContext context) {
    final codeCtrl = TextEditingController();
    _quickAction(context, "New Coupon", "Coupon created", (setState, values) => [
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Coupon code", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "Discount (e.g. 10% or Rs 500)", border: OutlineInputBorder())),
        ]);
  }

  void _newFlashSale(BuildContext context) {
    _quickAction(context, "New Flash Sale", "Flash sale scheduled", (setState, values) => [
          const TextField(decoration: InputDecoration(labelText: "Sale name", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "Discount %", border: OutlineInputBorder())),
        ]);
  }

  void _scheduleBanner(BuildContext context) {
    _quickAction(context, "Schedule Banner", "Banner scheduled", (setState, values) => [
          const TextField(decoration: InputDecoration(labelText: "Banner title", border: OutlineInputBorder())),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: "Image URL", border: OutlineInputBorder())),
        ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);
    return AdminShell(
      currentPath: "/admin/promotions",
      title: "Promotions",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(onPressed: () => _newCoupon(context), icon: const Icon(Icons.add), label: const Text("New Coupon")),
                OutlinedButton.icon(onPressed: () => _newFlashSale(context), icon: const Icon(Icons.bolt_outlined), label: const Text("New Flash Sale")),
                OutlinedButton.icon(onPressed: () => _scheduleBanner(context), icon: const Icon(Icons.image_outlined), label: const Text("Schedule Banner")),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: couponsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(message: "Could not load promotions", onRetry: () => ref.invalidate(couponsProvider)),
                data: (coupons) {
                  if (coupons.isEmpty) {
                    return Center(child: Text("No active promotions", style: bodyFont(fontSize: 13, color: AppColors.inkSoft)));
                  }
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      return ListView.separated(
                        itemCount: coupons.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                        itemBuilder: (context, i) {
                          final c = coupons[i];
                          final active = c["active"] == true;
                          final validUntil = DateTime.tryParse(c["validUntil"]?.toString() ?? "");
                          final usageCount = c["usageCount"] ?? 0;
                          final usageLimit = c["usageLimit"] ?? 0;
                          return ListTile(
                            leading: const Icon(Icons.local_offer_outlined, color: AppColors.ink),
                            title: Text("${c["code"]} — ${c["discountLabel"]}", style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              wide ? "${c["description"]} · $usageCount/$usageLimit used" : c["description"]?.toString() ?? "",
                              style: bodyFont(fontSize: 12, color: AppColors.inkSoft),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (wide && validUntil != null) ...[
                                  Text("Till ${validUntil.day}/${validUntil.month}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                                  const SizedBox(width: 12),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: (active ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadii.chip),
                                  ),
                                  child: Text(
                                    active ? "Active" : "Inactive",
                                    style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: active ? AppColors.success : AppColors.warning),
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
}
