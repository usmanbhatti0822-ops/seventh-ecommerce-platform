import "package:flutter/material.dart";
import "../../features/catalog/domain/entities/product.dart";
import "../theme/app_theme.dart";

/// Editorial-style product card — full-bleed image, tag badge, name+price
/// row below (matches the "Seventh" reference site's catalog cards).
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleWishlist;
  final bool isWishlisted;
  final String? tag;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.onToggleWishlist,
    this.isWishlisted = false,
    this.tag,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: "product-${p.id}",
                  child: AnimatedScale(
                    scale: _pressed ? 1.05 : 1.0,
                    duration: AppDurations.medium,
                    curve: Curves.easeOut,
                    child: ClipRect(
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : Container(color: AppColors.paperDim),
                        errorBuilder: (_, __, ___) => Container(color: AppColors.paperDim),
                      ),
                    ),
                  ),
                ),
                if (widget.tag != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: AppColors.ink,
                      child: Text(
                        widget.tag!.toUpperCase(),
                        style: eyebrowFont(color: AppColors.paper).copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onToggleWishlist,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      color: AppColors.paper.withOpacity(0.9),
                      child: Icon(
                        widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: widget.isWishlisted ? AppColors.rust : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bodyFont(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              Text(
                "Rs ${p.price.toStringAsFixed(0)}",
                style: _priceStyle(),
              ),
            ],
          ),
          if (p.oldPrice != null) ...[
            const SizedBox(height: 2),
            Text(
              "Rs ${p.oldPrice!.toStringAsFixed(0)}",
              style: bodyFont(fontSize: 11, color: AppColors.inkSoft).copyWith(
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TextStyle _priceStyle() => displayFont(fontSize: 14, letterSpacing: 0.3);
