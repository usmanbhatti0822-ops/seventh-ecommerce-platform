import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/cart_repository.dart";
import "../../../../core/network/api_result.dart";

final cartRepositoryProvider = Provider((ref) => CartRepository());

/// Cart state as a StateNotifier so add/update/remove can optimistically
/// mutate local state while the API call is in flight.
class CartState {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final bool mutating;
  final String? error;
  const CartState({this.items = const [], this.loading = false, this.mutating = false, this.error});

  double get subtotal => items.fold(0.0, (sum, i) => sum + (i["price"] as num) * (i["qty"] as num));
  int get itemCount => items.fold(0, (sum, i) => sum + (i["qty"] as num).toInt());

  CartState copyWith({List<Map<String, dynamic>>? items, bool? loading, bool? mutating, String? error}) =>
      CartState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        mutating: mutating ?? this.mutating,
        error: error,
      );
}

class CartNotifier extends StateNotifier<CartState> {
  final CartRepository repo;
  CartNotifier(this.repo) : super(const CartState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    final result = await repo.getCart();
    switch (result) {
      case ApiSuccess(data: final cart):
        state = state.copyWith(items: List<Map<String, dynamic>>.from(cart["items"] ?? []), loading: false);
      case ApiFailure(message: final msg):
        state = state.copyWith(loading: false, error: msg);
    }
  }

  Future<String?> addItem(String variantId, int qty) async {
    final result = await repo.addItem(variantId, qty);
    switch (result) {
      case ApiSuccess():
        await load();
        return null;
      case ApiFailure(message: final msg):
        return msg;
    }
  }

  Future<void> updateQty(String itemId, int qty) async {
    // Optimistic update so the stepper feels instant, then reconcile with the server.
    final optimistic = state.items.map((i) => i["id"] == itemId ? {...i, "qty": qty} : i).toList();
    state = state.copyWith(items: optimistic, mutating: true);
    final result = await repo.updateItemQty(itemId, qty);
    if (result is ApiSuccess) {
      await load();
    }
    state = state.copyWith(mutating: false);
  }

  Future<void> removeItem(String itemId) async {
    final optimistic = state.items.where((i) => i["id"] != itemId).toList();
    state = state.copyWith(items: optimistic, mutating: true);
    final result = await repo.removeItem(itemId);
    if (result is ApiSuccess) await load();
    state = state.copyWith(mutating: false);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref.watch(cartRepositoryProvider));
});
