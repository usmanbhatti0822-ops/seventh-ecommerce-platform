import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fl_chart/fl_chart.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin_shell.dart";
import "../../../../admin/data/providers/admin_provider.dart";

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);
    return AdminShell(
      currentPath: "/admin/reports",
      title: "Reports",
      child: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: "Could not load reports", onRetry: () => ref.invalidate(adminReportsProvider)),
        data: (data) {
          final salesByCategory = (data["salesByCategory"] as List).cast<Map<String, dynamic>>();
          final supplierPerformance = (data["supplierPerformance"] as List).cast<Map<String, dynamic>>();
          final returnRate = (data["returnRate"] as num?) ?? 0;
          final repeatPurchaseRate = (data["repeatPurchaseRate"] as num?) ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SALES BY CATEGORY", style: eyebrowFont()),
                const SizedBox(height: 12),
                Container(
                  height: 280,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                  child: salesByCategory.isEmpty
                      ? Center(child: Text("No category sales data", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)))
                      : BarChart(
                          BarChartData(
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      salesByCategory[value.toInt() % salesByCategory.length]["category"].toString(),
                                      style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft),
                                    ),
                                  ),
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.line, strokeWidth: 1)),
                            borderData: FlBorderData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.ink,
                                getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
                                  "Rs ${rod.toY.round()}",
                                  bodyFont(fontSize: 11, color: AppColors.paper),
                                ),
                              ),
                            ),
                            barGroups: List.generate(salesByCategory.length, (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: (salesByCategory[i]["revenue"] as num).toDouble(),
                                      color: AppColors.olive,
                                      width: 26,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ],
                                )),
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                Text("SUPPLIER PERFORMANCE", style: eyebrowFont()),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
                  child: supplierPerformance.isEmpty
                      ? Padding(padding: const EdgeInsets.all(20), child: Text("No supplier data", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)))
                      : Column(
                          children: [
                            for (int i = 0; i < supplierPerformance.length; i++) ...[
                              if (i > 0) const Divider(height: 1, color: AppColors.line),
                              ListTile(
                                leading: const Icon(Icons.local_shipping_outlined, color: AppColors.ink),
                                title: Text(supplierPerformance[i]["supplier"].toString(), style: bodyFont(fontSize: 13.5, fontWeight: FontWeight.w700)),
                                subtitle: Text("${supplierPerformance[i]["ordersFulfilled"]} orders fulfilled · ${supplierPerformance[i]["avgDeliveryDays"]}d avg delivery", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                                trailing: Text("${supplierPerformance[i]["fulfillmentRate"]}% on-time", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.olive)),
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(builder: (context, constraints) {
                  final wide = constraints.maxWidth > 600;
                  final cards = [
                    _MetricCard(label: "Return Rate", value: "$returnRate%", color: returnRate > 5 ? Colors.redAccent : AppColors.success),
                    _MetricCard(label: "Repeat Purchase Rate", value: "$repeatPurchaseRate%", color: AppColors.olive),
                  ];
                  return Flex(
                    direction: wide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < cards.length; i++) ...[
                        if (i > 0) SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
                        wide ? Expanded(child: cards[i]) : cards[i],
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: eyebrowFont()),
          const SizedBox(height: 10),
          Text(value, style: displayFont(fontSize: 26, color: color)),
        ],
      ),
    );
  }
}
