import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/reviews_repository.dart";
import "../../../../core/network/api_result.dart";

final reviewsRepositoryProvider = Provider((ref) => ReviewsRepository());

final productReviewsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, productId) async {
  final repo = ref.watch(reviewsRepositoryProvider);
  final result = await repo.forProduct(productId);
  return switch (result) {
    ApiSuccess(data: final reviews) => reviews,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});
