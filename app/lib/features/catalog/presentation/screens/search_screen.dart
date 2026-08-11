import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "../providers/catalog_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../../../../core/widgets/product_card.dart";
import "../../../../core/widgets/shimmer_loader.dart";
import "../../../../core/widgets/empty_view.dart";
import "../../../../core/widgets/error_view.dart";
import "../../../wishlist/presentation/providers/wishlist_provider.dart";

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum SortOption { relevance, priceLowHigh, priceHighLow, rating }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = "";
  SortOption _sort = SortOption.relevance;
  RangeValues _priceRange = const RangeValues(0, 10000);

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: SortOption.values.map((opt) {
                  return ChoiceChip(
                    label: Text(_sortLabel(opt)),
                    selected: _sort == opt,
                    onSelected: (_) => setSheetState(() => _sort = opt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text("Price Range (Rs)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 10000,
                divisions: 20,
                labels: RangeLabels(_priceRange.start.round().toString(), _priceRange.end.round().toString()),
                onChanged: (v) => setSheetState(() => _priceRange = v),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("Apply Filters"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sortLabel(SortOption o) => switch (o) {
        SortOption.relevance => "Relevance",
        SortOption.priceLowHigh => "Price: Low to High",
        SortOption.priceHighLow => "Price: High to Low",
        SortOption.rating => "Top Rated",
      };

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_query.isEmpty ? null : _query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Search products...", border: InputBorder.none),
          onSubmitted: (v) => setState(() => _query = v),
        ),
        actions: [
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.tune)),
        ],
      ),
      body: productsAsync.when(
        loading: () => const ShimmerGrid(),
        error: (err, _) => ErrorView(message: "Search failed", onRetry: () => ref.invalidate(productsProvider(_query))),
        data: (products) {
          var filtered = products
              .where((p) => p.price >= _priceRange.start && p.price <= _priceRange.end)
              .toList();
          switch (_sort) {
            case SortOption.priceLowHigh:
              filtered.sort((a, b) => a.price.compareTo(b.price));
            case SortOption.priceHighLow:
              filtered.sort((a, b) => b.price.compareTo(a.price));
            case SortOption.rating:
              filtered.sort((a, b) => b.rating.compareTo(a.rating));
            case SortOption.relevance:
              break;
          }
          if (filtered.isEmpty) {
            return const EmptyView(message: "No products match your search", icon: Icons.search_off);
          }
          final wishlist = ref.watch(wishlistProvider);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.68,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final p = filtered[i];
              return ProductCard(
                product: p,
                tag: p.badge,
                isWishlisted: wishlist.ids.contains(p.id),
                onTap: () => context.push("/product/${p.id}"),
                onToggleWishlist: () => ref.read(wishlistProvider.notifier).toggle(p.id),
              );
            },
          );
        },
      ),
    );
  }
}
