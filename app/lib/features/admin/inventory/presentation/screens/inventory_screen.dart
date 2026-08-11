import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";

/// Stock table for every product variant across warehouses. Reuses
/// [adminInventoryProvider] (backed by `GET /admin/inventory` in the mock
/// backend) — rows where stockQty <= lowStockThreshold are flagged as low
/// stock with a highlighted row and a "Show low stock only" filter.
class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  bool _lowStockOnly = false;

  bool _isLow(Map<String, dynamic> item) => (item["stockQty"] as num) <= (item["lowStockThreshold"] as num);

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(adminInventoryProvider);
    return AdminShell(
      currentPath: "/admin/inventory",
      title: "Inventory",
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilterChip(
                  label: const Text("Show low stock only"),
                  selected: _lowStockOnly,
                  onSelected: (v) => setState(() => _lowStockOnly = v),
                  avatar: Icon(Icons.warning_amber_rounded, size: 16, color: _lowStockOnly ? AppColors.paper : AppColors.warning),
                  selectedColor: AppColors.warning,
                  labelStyle: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: _lowStockOnly ? AppColors.paper : AppColors.ink),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.line),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ErrorView(message: "Could not load inventory", onRetry: () => ref.invalidate(adminInventoryProvider)),
                data: (inventory) {
                  final rows = _lowStockOnly ? inventory.where(_isLow).toList() : inventory;
                  if (rows.isEmpty) {
                    return Center(
                      child: Text(
                        _lowStockOnly ? "No low-stock items" : "No inventory records",
                        style: bodyFont(fontSize: 13, color: AppColors.inkSoft),
                      ),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth > 760;
                      return Column(
                        children: [
                          if (wide) _HeaderRow(),
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                              itemBuilder: (context, i) => wide ? _InventoryRowWide(item: rows[i], low: _isLow(rows[i])) : _InventoryCard(item: rows[i], low: _isLow(rows[i])),
                            ),
                          ),
                        ],
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

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = eyebrowFont();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text("SKU", style: style)),
          Expanded(flex: 3, child: Text("PRODUCT", style: style)),
          Expanded(flex: 2, child: Text("WAREHOUSE", style: style)),
          Expanded(flex: 2, child: Text("STOCK", style: style)),
          Expanded(flex: 2, child: Text("LAST RESTOCKED", style: style)),
        ],
      ),
    );
  }
}

class _InventoryRowWide extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool low;
  const _InventoryRowWide({required this.item, required this.low});

  @override
  Widget build(BuildContext context) {
    final restocked = DateTime.tryParse(item["lastRestockedAt"]?.toString() ?? "");
    return Container(
      color: low ? AppColors.warning.withOpacity(0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(item["sku"]?.toString() ?? "", style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(item["productName"]?.toString() ?? "", style: bodyFont(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Text(item["warehouseLocation"]?.toString() ?? "", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft))),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (low) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.warning)),
                Text(
                  "${item["stockQty"]}",
                  style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: low ? AppColors.warning : AppColors.ink),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(restocked != null ? "${restocked.day}/${restocked.month}/${restocked.year}" : "—", style: bodyFont(fontSize: 12, color: AppColors.inkSoft))),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool low;
  const _InventoryCard({required this.item, required this.low});

  @override
  Widget build(BuildContext context) {
    final restocked = DateTime.tryParse(item["lastRestockedAt"]?.toString() ?? "");
    return Container(
      color: low ? AppColors.warning.withOpacity(0.08) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(item["productName"]?.toString() ?? "", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700))),
              if (low) const Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.warning),
              const SizedBox(width: 4),
              Text("${item["stockQty"]} left", style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700, color: low ? AppColors.warning : AppColors.ink)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "SKU ${item["sku"]} · ${item["warehouseLocation"]} · Restocked ${restocked != null ? "${restocked.day}/${restocked.month}/${restocked.year}" : "—"}",
            style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
