import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/wishlist_repository.dart";
import "../../../../core/network/api_result.dart";
import "../../../catalog/domain/entities/product.dart";

final wishlistRepositoryProvider = Provider((ref) => WishlistRepository());

class WishlistState {
  final Set<String> ids;
  final List<Product> products;
  final bool loading;
  const WishlistState({this.ids = const {}, this.products = const [], this.loading = false});
}

/// App-wide wishlist state (shared by Home, Search, Product Detail, and the
/// Wishlist screen) so the heart icon stays in sync everywhere at once.
class WishlistNotifier extends StateNotifier<WishlistState> {
  final WishlistRepository repo;
  WishlistNotifier(this.repo) : super(const WishlistState()) {
    load();
  }

  Future<void> load() async {
    state = WishlistState(ids: state.ids, products: state.products, loading: true);
    final result = await repo.list();
    switch (result) {
      case ApiSuccess(data: final products):
        state = WishlistState(ids: products.map((p) => p.id).toSet(), products: products, loading: false);
      case ApiFailure():
        state = WishlistState(ids: state.ids, products: state.products, loading: false);
    }
  }

  Future<void> toggle(String productId) async {
    final isWishlisted = state.ids.contains(productId);
    final optimisticIds = Set<String>.from(state.ids);
    isWishlisted ? optimisticIds.remove(productId) : optimisticIds.add(productId);
    state = WishlistState(ids: optimisticIds, products: state.products, loading: state.loading);
    final result = isWishlisted ? await repo.remove(productId) : await repo.add(productId);
    if (result is ApiSuccess) await load();
  }
}

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(ref.watch(wishlistRepositoryProvider));
});
