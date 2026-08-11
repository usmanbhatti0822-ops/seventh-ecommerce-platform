import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/checkout_provider.dart";
import "../../../cart/presentation/providers/cart_provider.dart";
import "../../../orders/presentation/providers/orders_provider.dart";
import "../../../promotions/presentation/providers/promotions_provider.dart";
import "../../../../core/network/api_result.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/error_view.dart";

const _stepLabels = ["Address", "Delivery", "Payment", "Review"];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponController = TextEditingController();
  String? _couponError;
  bool _applyingCoupon = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final coupons = await ref.read(couponsProvider.future);
      final match = coupons.where((c) => c["code"].toString().toUpperCase() == code.toUpperCase()).toList();
      if (match.isEmpty) {
        setState(() => _couponError = "Invalid or expired code");
      } else {
        ref.read(appliedCouponProvider.notifier).state = match.first;
      }
    } catch (_) {
      setState(() => _couponError = "Could not validate code — try again");
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  Future<void> _placeOrder() async {
    final addressId = ref.read(selectedAddressIdProvider);
    if (addressId == null) return;
    ref.read(placingOrderProvider.notifier).state = true;
    final repo = ref.read(ordersRepositoryProvider);
    final coupon = ref.read(appliedCouponProvider);
    final result = await repo.placeOrder(
      addressId: addressId,
      paymentMethod: ref.read(paymentMethodProvider),
      couponCode: coupon?["code"]?.toString(),
    );
    ref.read(placingOrderProvider.notifier).state = false;
    switch (result) {
      case ApiSuccess(data: final order):
        await ref.read(cartProvider.notifier).load();
        ref.invalidate(myOrdersProvider);
        if (mounted) context.pushReplacement("/order-success", extra: order);
      case ApiFailure(message: final msg):
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(checkoutStepProvider);
    final cart = ref.watch(cartProvider);
    final canContinue = switch (step) {
      0 => ref.watch(selectedAddressIdProvider) != null,
      _ => true,
    };
    final placing = ref.watch(placingOrderProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Checkout")),
      body: Column(
        children: [
          _StepHeader(step: step),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDurations.medium,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim), child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey(step),
                child: switch (step) {
                  0 => const _AddressStep(),
                  1 => const _DeliveryStep(),
                  2 => _PaymentStep(
                      couponController: _couponController,
                      couponError: _couponError,
                      applying: _applyingCoupon,
                      onApplyCoupon: _applyCoupon,
                    ),
                  _ => _ReviewStep(cart: cart),
                },
              ),
            ),
          ),
          _BottomBar(
            step: step,
            canContinue: canContinue,
            placing: placing,
            cartEmpty: cart.items.isEmpty,
            onBack: () => ref.read(checkoutStepProvider.notifier).state = step - 1,
            onContinue: () {
              if (step == 3) {
                _placeOrder();
              } else {
                ref.read(checkoutStepProvider.notifier).state = step + 1;
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  const _StepHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(_stepLabels.length, (i) {
          final active = i <= step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == _stepLabels.length - 1 ? 0 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppDurations.medium,
                    height: 3,
                    decoration: BoxDecoration(color: active ? AppColors.ink : AppColors.line),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepLabels[i].toUpperCase(),
                    style: eyebrowFont(color: active ? AppColors.ink : AppColors.inkSoft.withOpacity(0.5)).copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AddressStep extends ConsumerWidget {
  const _AddressStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressIdProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text("Delivery Address", style: displayFont(fontSize: 22)),
        const SizedBox(height: 16),
        addressesAsync.when(
          loading: () => const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator())),
          error: (err, _) => ErrorView(message: "Could not load addresses", onRetry: () => ref.invalidate(addressesProvider)),
          data: (addresses) {
            if (selected == null && addresses.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(selectedAddressIdProvider.notifier).state = addresses.firstWhere(
                  (a) => a["isDefault"] == true,
                  orElse: () => addresses.first,
                )["id"];
              });
            }
            return Column(
              children: [
                ...addresses.map((addr) {
                  final isSelected = addr["id"] == selected;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => ref.read(selectedAddressIdProvider.notifier).state = addr["id"],
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paperDim,
                          border: Border.all(color: isSelected ? AppColors.ink : Colors.transparent, width: 1.4),
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                        child: Row(
                          children: [
                            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.ink, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(addr["label"], style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text("${addr["line1"]}, ${addr["city"]}", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                                  Text(addr["phone"], style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: () => _showAddAddressSheet(context, ref),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("ADD NEW ADDRESS"),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showAddAddressSheet(BuildContext context, WidgetRef ref) {
    final labelCtl = TextEditingController(text: "Home");
    final line1Ctl = TextEditingController();
    final cityCtl = TextEditingController();
    final phoneCtl = TextEditingController(text: "+92");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Address", style: displayFont(fontSize: 20)),
            const SizedBox(height: 16),
            TextField(controller: labelCtl, decoration: const InputDecoration(labelText: "Label (Home/Office)")),
            const SizedBox(height: 10),
            TextField(controller: line1Ctl, decoration: const InputDecoration(labelText: "Street Address")),
            const SizedBox(height: 10),
            TextField(controller: cityCtl, decoration: const InputDecoration(labelText: "City")),
            const SizedBox(height: 10),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: "Phone")),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (line1Ctl.text.trim().isEmpty || cityCtl.text.trim().isEmpty) return;
                  final repo = ref.read(addressesRepositoryProvider);
                  final result = await repo.add({
                    "label": labelCtl.text.trim().isEmpty ? "Address" : labelCtl.text.trim(),
                    "line1": line1Ctl.text.trim(),
                    "city": cityCtl.text.trim(),
                    "phone": phoneCtl.text.trim(),
                    "isDefault": false,
                  });
                  if (result is ApiSuccess) {
                    ref.invalidate(addressesProvider);
                    ref.read(selectedAddressIdProvider.notifier).state = (result as ApiSuccess).data["id"];
                  }
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Text("SAVE ADDRESS"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStep extends ConsumerWidget {
  const _DeliveryStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(deliveryOptionProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text("Delivery Method", style: displayFont(fontSize: 22)),
        const SizedBox(height: 16),
        ...DeliveryOption.values.map((opt) {
          final isSelected = opt == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => ref.read(deliveryOptionProvider.notifier).state = opt,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  border: Border.all(color: isSelected ? AppColors.ink : Colors.transparent, width: 1.4),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Row(
                  children: [
                    Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.ink, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(opt.label, style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600))),
                    Text(opt.fee == 0 ? "FREE" : "Rs ${opt.fee.toStringAsFixed(0)}", style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PaymentStep extends ConsumerWidget {
  final TextEditingController couponController;
  final String? couponError;
  final bool applying;
  final VoidCallback onApplyCoupon;
  const _PaymentStep({required this.couponController, required this.couponError, required this.applying, required this.onApplyCoupon});

  static const _methods = ["Cash on Delivery", "JazzCash", "Easypaisa", "Card"];
  static const _icons = [Icons.local_shipping_outlined, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_outlined, Icons.credit_card_outlined];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(paymentMethodProvider);
    final coupon = ref.watch(appliedCouponProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text("Payment Method", style: displayFont(fontSize: 22)),
        const SizedBox(height: 16),
        ...List.generate(_methods.length, (i) {
          final isSelected = _methods[i] == selected;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => ref.read(paymentMethodProvider.notifier).state = _methods[i],
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.paperDim,
                  border: Border.all(color: isSelected ? AppColors.ink : Colors.transparent, width: 1.4),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Row(
                  children: [
                    Icon(_icons[i], size: 18, color: AppColors.ink),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_methods[i], style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600))),
                    Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: AppColors.ink, size: 20),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Text("Demo mode — no real payment credentials are used; every method simulates a successful transaction.",
            style: bodyFont(fontSize: 11, color: AppColors.inkSoft)),
        const SizedBox(height: 24),
        Text("Promo Code", style: displayFont(fontSize: 18)),
        const SizedBox(height: 12),
        if (coupon != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.olive.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadii.card)),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: AppColors.olive, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("${coupon["code"]} applied — ${coupon["discountLabel"]}",
                      style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.olive)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () {
                    ref.read(appliedCouponProvider.notifier).state = null;
                    couponController.clear();
                  },
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(hintText: "Enter code (try WELCOME10)", errorText: couponError),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: applying ? null : onApplyCoupon,
                child: applying
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("APPLY"),
              ),
            ],
          ),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  final CartState cart;
  const _ReviewStep({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressId = ref.watch(selectedAddressIdProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final delivery = ref.watch(deliveryOptionProvider);
    final payment = ref.watch(paymentMethodProvider);
    final coupon = ref.watch(appliedCouponProvider);

    final subtotal = cart.subtotal;
    final shippingFee = subtotal >= 5000 ? 0.0 : delivery.fee;
    double discount = 0;
    if (coupon != null) {
      discount = coupon["discountType"] == "percentage" ? subtotal * (coupon["discountValue"] as num) / 100 : (coupon["discountValue"] as num).toDouble();
    }
    final total = (subtotal + shippingFee - discount).clamp(0, double.infinity);

    final address = addressesAsync.maybeWhen(
      data: (list) => list.where((a) => a["id"] == addressId).toList(),
      orElse: () => <Map<String, dynamic>>[],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text("Review Order", style: displayFont(fontSize: 22)),
        const SizedBox(height: 16),
        if (address.isNotEmpty) _sectionCard("DELIVERING TO", "${address.first["line1"]}, ${address.first["city"]}"),
        const SizedBox(height: 10),
        _sectionCard("DELIVERY", delivery.label),
        const SizedBox(height: 10),
        _sectionCard("PAYMENT", payment),
        const SizedBox(height: 20),
        ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(2), child: Image.network(item["imageUrl"], width: 44, height: 54, fit: BoxFit.cover)),
                  const SizedBox(width: 10),
                  Expanded(child: Text("${item["name"]} × ${item["qty"]}", style: bodyFont(fontSize: 12.5))),
                  Text("Rs ${((item["price"] as num) * (item["qty"] as num)).toStringAsFixed(0)}", style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        const Divider(height: 24, color: AppColors.line),
        _summaryRow("Subtotal", "Rs ${subtotal.toStringAsFixed(0)}"),
        const SizedBox(height: 6),
        _summaryRow("Shipping", shippingFee == 0 ? "FREE" : "Rs ${shippingFee.toStringAsFixed(0)}"),
        if (discount > 0) ...[
          const SizedBox(height: 6),
          _summaryRow("Discount", "-Rs ${discount.toStringAsFixed(0)}", color: AppColors.olive),
        ],
        const Divider(height: 24, color: AppColors.line),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("TOTAL", style: eyebrowFont()),
            Text("Rs ${total.toStringAsFixed(0)}", style: displayFont(fontSize: 20)),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard(String label, String value) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.paperDim, borderRadius: BorderRadius.circular(AppRadii.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: eyebrowFont(color: AppColors.inkSoft).copyWith(fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _summaryRow(String label, String value, {Color? color}) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
          Text(value, style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: color ?? AppColors.ink)),
        ],
      );
}

class _BottomBar extends StatelessWidget {
  final int step;
  final bool canContinue;
  final bool placing;
  final bool cartEmpty;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  const _BottomBar({
    required this.step,
    required this.canContinue,
    required this.placing,
    required this.cartEmpty,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(color: AppColors.paper, border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            if (step > 0) ...[
              OutlinedButton(onPressed: placing ? null : onBack, child: const Text("BACK")),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: (!canContinue || placing || (step == 3 && cartEmpty)) ? null : onContinue,
                child: placing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(step == 3 ? "PLACE ORDER" : "CONTINUE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
