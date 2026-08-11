import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../../../catalog/presentation/providers/catalog_provider.dart";
import "../../../catalog/domain/entities/product.dart";
import "../../../cart/presentation/providers/cart_provider.dart";
import "../../../wishlist/presentation/providers/wishlist_provider.dart";
import "../../../reviews/presentation/widgets/reviews_section.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/product_card.dart";
import "../../../../core/widgets/error_view.dart";

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int? _selectedVariantIndex;
  int _galleryIndex = 0;
  int _qty = 1;
  bool _addingToCart = false;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorView(message: "Could not load this product", onRetry: () => ref.invalidate(productDetailProvider(widget.productId))),
        data: (product) => _buildContent(context, product),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _buildBottomBar(context, product),
        orElse: () => null,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, Product product) {
    final selectedVariant = product.variants.isNotEmpty && _selectedVariantIndex != null && _selectedVariantIndex! < product.variants.length
        ? product.variants[_selectedVariantIndex!]
        : null;
    final outOfStock = selectedVariant != null && selectedVariant.stockQty <= 0;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: AppColors.paper, border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (_addingToCart || outOfStock) ? null : () => _addToCart(product, buyNow: false),
                child: _addingToCart
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("ADD TO BAG"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_addingToCart || outOfStock) ? null : () => _addToCart(product, buyNow: true),
                child: Text(outOfStock ? "OUT OF STOCK" : "BUY NOW"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Product product) {
    _selectedVariantIndex ??= product.variants.indexWhere((v) => v.stockQty > 0);
    if (_selectedVariantIndex == -1) _selectedVariantIndex = 0;
    final selectedVariant = product.variants.isNotEmpty && _selectedVariantIndex! < product.variants.length
        ? product.variants[_selectedVariantIndex!]
        : null;
    final outOfStock = selectedVariant != null && selectedVariant.stockQty <= 0;
    final wishlist = ref.watch(wishlistProvider);
    final isWishlisted = wishlist.ids.contains(product.id);
    final discountPct = product.oldPrice != null && product.oldPrice! > product.price
        ? (((product.oldPrice! - product.price) / product.oldPrice!) * 100).round()
        : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 460,
          pinned: true,
          backgroundColor: AppColors.paper,
          foregroundColor: AppColors.ink,
          actions: [
            IconButton(
              icon: Icon(isWishlisted ? Icons.favorite : Icons.favorite_border, color: isWishlisted ? AppColors.rust : AppColors.ink),
              onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: "product-${product.id}",
                  child: PageView.builder(
                    itemCount: product.images.isEmpty ? 1 : product.images.length,
                    onPageChanged: (i) => setState(() => _galleryIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      product.images.isEmpty ? product.imageUrl : product.images[i],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product.images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(product.images.length, (i) {
                        final active = i == _galleryIndex;
                        return AnimatedContainer(
                          duration: AppDurations.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.25)),
                        );
                      }),
                    ),
                  ),
                if (product.badge != null)
                  Positioned(
                    top: 100,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: AppColors.ink,
                      child: Text(product.badge!.toUpperCase(), style: eyebrowFont(color: AppColors.paper).copyWith(fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.category.toUpperCase(), style: eyebrowFont()),
                const SizedBox(height: 6),
                Text(product.name, style: displayFont(fontSize: 26)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text("${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)",
                        style: bodyFont(fontSize: 12.5, color: AppColors.inkSoft)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Rs ${product.price.toStringAsFixed(0)}", style: displayFont(fontSize: 24)),
                    if (product.oldPrice != null) ...[
                      const SizedBox(width: 10),
                      Text("Rs ${product.oldPrice!.toStringAsFixed(0)}",
                          style: bodyFont(fontSize: 14, color: AppColors.inkSoft).copyWith(decoration: TextDecoration.lineThrough)),
                    ],
                    if (discountPct != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppColors.rust.withValues(alpha: 0.12),
                        child: Text("-$discountPct%", style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.rust)),
                      ),
                    ],
                  ],
                ),
                if (product.variants.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text("SELECT SIZE", style: eyebrowFont()),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(product.variants.length, (i) {
                      final v = product.variants[i];
                      final selected = i == _selectedVariantIndex;
                      final disabled = v.stockQty <= 0;
                      return GestureDetector(
                        onTap: disabled ? null : () => setState(() { _selectedVariantIndex = i; _qty = 1; }),
                        child: AnimatedContainer(
                          duration: AppDurations.fast,
                          width: 52,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.ink : Colors.transparent,
                            border: Border.all(color: disabled ? AppColors.line : AppColors.ink),
                          ),
                          child: Text(
                            v.size ?? "—",
                            style: bodyFont(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: disabled ? AppColors.inkSoft.withValues(alpha: 0.4) : (selected ? AppColors.paper : AppColors.ink),
                            ).copyWith(decoration: disabled ? TextDecoration.lineThrough : null),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (outOfStock)
                    Text("Out of stock in this size", style: bodyFont(fontSize: 12, color: Colors.redAccent))
                  else if (selectedVariant != null && selectedVariant.stockQty <= 5)
                    Text("Only ${selectedVariant.stockQty} left in stock", style: bodyFont(fontSize: 12, color: AppColors.rust)),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Text("QUANTITY", style: eyebrowFont())),
                    _qtyStepper(),
                  ],
                ),
                const SizedBox(height: 24),
                Text("DESCRIPTION", style: eyebrowFont()),
                const SizedBox(height: 8),
                Text(
                  product.description.isNotEmpty
                      ? product.description
                      : "High quality product sourced for our marketplace. Fast delivery across Pakistan with cash on delivery available.",
                  style: bodyFont(fontSize: 13.5, color: AppColors.inkSoft, letterSpacing: 0.1).copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                ReviewsSection(productId: product.id),
                const SizedBox(height: 28),
                _relatedProducts(context, product),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _qtyStepper() {
    return Row(
      children: [
        _stepperBtn(Icons.remove, () => setState(() => _qty = (_qty - 1).clamp(1, 99))),
        Container(width: 36, alignment: Alignment.center, child: Text("$_qty", style: bodyFont(fontSize: 14, fontWeight: FontWeight.w700))),
        _stepperBtn(Icons.add, () => setState(() => _qty = (_qty + 1).clamp(1, 99))),
      ],
    );
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
          child: Icon(icon, size: 15, color: AppColors.ink),
        ),
      );

  Widget _relatedProducts(BuildContext context, Product product) {
    final relatedAsync = ref.watch(productsProvider(null));
    return relatedAsync.maybeWhen(
      data: (all) {
        final related = all.where((p) => p.category == product.category && p.id != product.id).take(4).toList();
        if (related.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("YOU MAY ALSO LIKE", style: eyebrowFont()),
            const SizedBox(height: 14),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => SizedBox(
                  width: 150,
                  child: ProductCard(
                    product: related[i],
                    onTap: () => context.push("/product/${related[i].id}"),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _addToCart(Product product, {required bool buyNow}) async {
    final variant = product.variants.isNotEmpty && _selectedVariantIndex! < product.variants.length
        ? product.variants[_selectedVariantIndex!]
        : null;
    if (variant == null) return;
    setState(() => _addingToCart = true);
    final error = await ref.read(cartProvider.notifier).addItem(variant.id, _qty);
    setState(() => _addingToCart = false);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    if (buyNow) {
      context.push("/checkout");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added to bag — ${product.name} (${variant.size ?? ""})"), duration: const Duration(seconds: 2)),
      );
    }
  }
}
