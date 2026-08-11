import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/wishlist_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/product_card.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/shimmer_loader.dart";

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text("Wishlist")),
      body: wishlist.loading && wishlist.products.isEmpty
          ? const ShimmerGrid()
          : wishlist.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EmptyView(message: "Nothing saved yet", icon: Icons.favorite_border),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: () => context.go("/"), child: const Text("DISCOVER PRODUCTS")),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 20, crossAxisSpacing: 16, childAspectRatio: 0.62,
                  ),
                  itemCount: wishlist.products.length,
                  itemBuilder: (context, i) {
                    final p = wishlist.products[i];
                    return ProductCard(
                      product: p,
                      isWishlisted: true,
                      onTap: () => context.push("/product/${p.id}"),
                      onToggleWishlist: () => ref.read(wishlistProvider.notifier).toggle(p.id),
                    );
                  },
                ),
    );
  }
}
