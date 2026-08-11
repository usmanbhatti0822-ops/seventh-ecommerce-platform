import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/cart_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/error_view.dart";

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(cartProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Your Bag")),
      body: _buildBody(cart),
      bottomNavigationBar: cart.items.isEmpty ? null : _buildSummaryBar(cart),
    );
  }

  Widget _buildBody(CartState cart) {
    if (cart.loading && cart.items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          height: 104,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
        ),
      );
    }
    if (cart.error != null) {
      return ErrorView(message: cart.error!, onRetry: () => ref.read(cartProvider.notifier).load());
    }
    if (cart.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyView(message: "Your bag is empty", icon: Icons.shopping_bag_outlined),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => context.go("/"), child: const Text("START SHOPPING")),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: cart.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _CartLine(
          key: ValueKey(item["id"]),
          item: item,
          onQtyChanged: (qty) => ref.read(cartProvider.notifier).updateQty(item["id"], qty),
          onRemove: () => ref.read(cartProvider.notifier).removeItem(item["id"]),
        );
      },
    );
  }

  Widget _buildSummaryBar(CartState cart) {
    final shipping = cart.subtotal >= 5000 ? 0.0 : 200.0;
    final total = cart.subtotal + shipping;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: const Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow("Subtotal (${cart.itemCount} items)", "Rs ${cart.subtotal.toStringAsFixed(0)}"),
            const SizedBox(height: 4),
            _summaryRow(
              "Shipping",
              shipping == 0 ? "FREE" : "Rs ${shipping.toStringAsFixed(0)}",
              valueColor: shipping == 0 ? AppColors.success : null,
            ),
            const Divider(height: 20, color: AppColors.line),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TOTAL", style: eyebrowFont()),
                Text("Rs ${total.toStringAsFixed(0)}", style: displayFont(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push("/checkout"),
                child: const Text("CHECKOUT"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          Text(value, style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.ink)),
        ],
      );
}

class _CartLine extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  const _CartLine({super.key, required this.item, required this.onQtyChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final qty = (item["qty"] as num).toInt();
    final price = (item["price"] as num).toDouble();
    return Dismissible(
      key: ValueKey("dismiss-${item["id"]}"),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(item["imageUrl"], width: 76, height: 92, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["name"], style: bodyFont(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  if (item["size"] != null)
                    Text("Size ${item["size"]}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                  const SizedBox(height: 8),
                  Text("Rs ${price.toStringAsFixed(0)}", style: displayFont(fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _stepperButton(Icons.remove, () => onQtyChanged(qty - 1)),
                      Container(
                        width: 32,
                        alignment: Alignment.center,
                        child: Text("$qty", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      _stepperButton(Icons.add, () => onQtyChanged(qty + 1)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.inkSoft),
              onPressed: onRemove,
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.line.withOpacity(0.6)), color: AppColors.paper),
          child: Icon(icon, size: 14, color: AppColors.ink),
        ),
      );
}
