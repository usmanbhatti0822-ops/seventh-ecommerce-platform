class ProductVariant {
  final String id;
  final String sku;
  final String? size;
  final String? color;
  final double price;
  final int stockQty;

  const ProductVariant({
    required this.id,
    required this.sku,
    this.size,
    this.color,
    required this.price,
    required this.stockQty,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json["id"],
        sku: json["sku"] ?? "",
        size: json["size"],
        color: json["color"],
        price: double.tryParse(json["price"].toString()) ?? 0,
        stockQty: json["stockQty"] ?? 0,
      );
}

class Product {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> images;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviewCount;
  final String category;
  final bool inStock;
  final List<ProductVariant> variants;
  final String? badge;
  final String description;

  const Product({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.images = const [],
    required this.price,
    this.oldPrice,
    required this.rating,
    required this.reviewCount,
    required this.category,
    this.inStock = true,
    this.variants = const [],
    this.badge,
    this.description = "",
  });

  /// Maps the backend Product shape (see backend/src/products, or the in-app
  /// mock backend in demo mode — core/network/mock_backend.dart) into the UI model.
  factory Product.fromJson(Map<String, dynamic> json) {
    final variants = (json["variants"] as List<dynamic>? ?? [])
        .map((v) => ProductVariant.fromJson(v))
        .toList();
    final images = (json["images"] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    return Product(
      id: json["id"],
      name: json["name"] ?? "",
      imageUrl: images.isNotEmpty ? images.first : "https://picsum.photos/seed/${json["id"]}/400/400",
      images: images,
      price: double.tryParse(json["basePrice"].toString()) ?? 0,
      oldPrice: json["oldPrice"] != null ? double.tryParse(json["oldPrice"].toString()) : null,
      rating: (json["rating"] as num?)?.toDouble() ?? 0,
      reviewCount: json["reviewCount"] ?? 0,
      category: json["category"]?["name"] ?? "",
      inStock: variants.isEmpty || variants.any((v) => v.stockQty > 0),
      variants: variants,
      badge: json["badge"] as String?,
      description: json["description"] as String? ?? "",
    );
  }
}

/// Mock catalog kept only as an offline/dev fallback (see CatalogRepository) —
/// no longer the primary data source once the backend is reachable.
final List<Product> mockProducts = List.generate(10, (i) {
  return Product(
    id: "p$i",
    name: "Product $i",
    imageUrl: "https://picsum.photos/seed/p$i/400/400",
    price: 1500 + (i * 250).toDouble(),
    oldPrice: i % 3 == 0 ? 2200 + (i * 250).toDouble() : null,
    rating: 3.5 + (i % 3) * 0.5,
    reviewCount: 10 + i * 4,
    category: ["Fashion", "Electronics", "Home", "Beauty"][i % 4],
  );
});
