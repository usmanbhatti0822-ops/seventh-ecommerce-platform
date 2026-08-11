import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:fl_chart/fl_chart.dart";
import "../../../../../core/theme/app_theme.dart";
import "../../../../../core/widgets/error_view.dart";
import "../../../../admin/data/providers/admin_provider.dart";
import "../../../../admin_shell.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    return AdminShell(
      currentPath: "/admin",
      title: "Dashboard",
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: "Could not load dashboard data", onRetry: () => ref.invalidate(adminDashboardProvider)),
        data: (data) => _DashboardBody(data: data),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 1100;
    final trend = (data["salesTrend"] as List).cast<Map<String, dynamic>>();
    final statusBreakdown = (data["orderStatusBreakdown"] as List).cast<Map<String, dynamic>>();
    final topProducts = (data["topProducts"] as List).cast<Map<String, dynamic>>();
    final lowStock = (data["lowStock"] as List).cast<Map<String, dynamic>>();
    final recentOrders = (data["recentOrders"] as List).cast<Map<String, dynamic>>();
    final recentActivity = (data["recentActivity"] as List).cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 1100 ? 5 : (constraints.maxWidth > 700 ? 3 : 2);
            final cardWidth = (constraints.maxWidth - (cols - 1) * 16) / cols;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(width: cardWidth, label: "Revenue", value: "Rs ${_fmt(data["revenue"])}", delta: data["revenueChangePct"], icon: Icons.trending_up, color: AppColors.olive),
                _StatCard(width: cardWidth, label: "Orders", value: "${data["orders"]}", delta: data["ordersChangePct"], icon: Icons.shopping_bag_outlined, color: AppColors.ink),
                _StatCard(width: cardWidth, label: "Customers", value: "${data["customers"]}", delta: data["customersChangePct"], icon: Icons.people_outline, color: AppColors.rust),
                _StatCard(width: cardWidth, label: "Avg. Order Value", value: "Rs ${_fmt(data["aov"])}", icon: Icons.receipt_long_outlined, color: AppColors.olive),
                _StatCard(width: cardWidth, label: "Conversion Rate", value: "${data["conversionRate"]}%", icon: Icons.query_stats, color: AppColors.rust),
              ],
            );
          }),
          const SizedBox(height: 28),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _SalesTrendCard(trend: trend)),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(child: _StatusBreakdownCard(breakdown: statusBreakdown)),
            ],
          ),
          const SizedBox(height: 16),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _TopProductsCard(products: topProducts)),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(child: _LowStockCard(items: lowStock)),
            ],
          ),
          const SizedBox(height: 16),
          Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: _RecentOrdersCard(orders: recentOrders)),
              SizedBox(width: wide ? 16 : 0, height: wide ? 0 : 16),
              Expanded(child: _ActivityCard(activity: recentActivity)),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(num v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(",");
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DashboardCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: eyebrowFont()),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final num? delta;
  final IconData icon;
  final Color color;
  const _StatCard({required this.width, required this.label, required this.value, this.delta, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadii.card), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (delta != null)
                  Row(
                    children: [
                      Icon(delta! >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: delta! >= 0 ? AppColors.success : Colors.redAccent),
                      Text("${delta!.abs()}%", style: bodyFont(fontSize: 11, fontWeight: FontWeight.w700, color: delta! >= 0 ? AppColors.success : Colors.redAccent)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => Opacity(
                opacity: t,
                child: Text(value, style: displayFont(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final List<Map<String, dynamic>> trend;
  const _SalesTrendCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(trend.length, (i) => FlSpot(i.toDouble(), (trend[i]["revenue"] as num).toDouble()));
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return _DashboardCard(
      title: "Sales — Last 14 Days",
      child: SizedBox(
        height: 240,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.2,
            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 3, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.line, strokeWidth: 1)),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.ink,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem("Rs ${s.y.round()}", bodyFont(fontSize: 11, color: AppColors.paper))).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.olive,
                barWidth: 2.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.olive.withValues(alpha: 0.22), AppColors.olive.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;
  const _StatusBreakdownCard({required this.breakdown});

  static const _colors = [AppColors.olive, AppColors.ink, AppColors.rust, Color(0xFFB8863B), Colors.redAccent];

  @override
  Widget build(BuildContext context) {
    final total = breakdown.fold(0, (s, b) => s + (b["count"] as int));
    return _DashboardCard(
      title: "Order Status",
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(breakdown.length, (i) {
                  final count = breakdown[i]["count"] as int;
                  return PieChartSectionData(
                    value: count.toDouble(),
                    color: _colors[i % _colors.length],
                    title: "",
                    radius: 22,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(breakdown.length, (i) {
                final count = breakdown[i]["count"] as int;
                final pct = total == 0 ? 0 : (count / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: _colors[i % _colors.length], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(breakdown[i]["status"], style: bodyFont(fontSize: 12))),
                      Text("$pct%", style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _TopProductsCard({required this.products});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: "Top Products",
      child: Column(
        children: products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(2), child: Image.network(p["image"], width: 36, height: 44, fit: BoxFit.cover)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p["name"], style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text("${p["unitsSold"]} sold", style: bodyFont(fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _LowStockCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: "Low Stock Alerts",
      child: items.isEmpty
          ? Text("All stock levels healthy", style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft))
          : Column(
              children: items.take(5).map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text(i["productName"], style: bodyFont(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text("${i["stockQty"]} left", style: bodyFont(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.orange)),
                      ],
                    ),
                  )).toList(),
            ),
    );
  }
}

class _RecentOrdersCard extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: "Recent Orders",
      child: Column(
        children: orders.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: Text(o["orderNumber"], style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700))),
                  Expanded(child: Text(o["status"], style: bodyFont(fontSize: 12, color: AppColors.inkSoft))),
                  Text("Rs ${(o["total"] as num).toStringAsFixed(0)}", style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: "Recent Activity",
      child: Column(
        children: activity.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: const EdgeInsets.only(top: 5), width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.olive, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a["text"], style: bodyFont(fontSize: 12.5))),
                  const SizedBox(width: 8),
                  Text(a["at"], style: bodyFont(fontSize: 10.5, color: AppColors.inkSoft)),
                ],
              ),
            )).toList(),
      ),
    );
  }
}
