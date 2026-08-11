import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../providers/reviews_provider.dart";
import "../../../../core/theme/app_theme.dart";
import "../screens/write_review_screen.dart";

class ReviewsSection extends ConsumerWidget {
  final String productId;
  const ReviewsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("REVIEWS", style: eyebrowFont()),
            TextButton(
              onPressed: () async {
                final submitted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => WriteReviewScreen(productId: productId)),
                );
                if (submitted == true) ref.invalidate(productReviewsProvider(productId));
              },
              child: const Text("Write a Review"),
            ),
          ],
        ),
        const SizedBox(height: 6),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text("Could not load reviews", style: bodyFont(fontSize: 12, color: AppColors.inkSoft)),
          ),
          data: (reviews) {
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text("No reviews yet — be the first to share your experience.",
                    style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
              );
            }
            final avg = reviews.fold(0.0, (s, r) => s + (r["rating"] as num)) / reviews.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text("${avg.toStringAsFixed(1)} · ${reviews.length} review${reviews.length == 1 ? "" : "s"}",
                        style: bodyFont(fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 14),
                ...reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.ink.withValues(alpha: 0.1),
                                child: Text(r["userName"][0], style: bodyFont(fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(width: 8),
                              Text(r["userName"], style: bodyFont(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              if (r["verified"] == true) ...[
                                const SizedBox(width: 6),
                                Text("· Verified", style: bodyFont(fontSize: 10.5, color: AppColors.olive)),
                              ],
                              const Spacer(),
                              Row(
                                children: List.generate(5, (i) => Icon(
                                      i < (r["rating"] as num) ? Icons.star : Icons.star_border,
                                      size: 13,
                                      color: Colors.amber,
                                    )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(r["comment"], style: bodyFont(fontSize: 13, color: AppColors.inkSoft)),
                        ],
                      ),
                    )),
              ],
            );
          },
        ),
      ],
    );
  }
}
