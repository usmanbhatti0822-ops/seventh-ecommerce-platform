import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/promotions_repository.dart";
import "../../../../core/network/api_result.dart";

final promotionsRepositoryProvider = Provider((ref) => PromotionsRepository());

final couponsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(promotionsRepositoryProvider);
  final result = await repo.list();
  return switch (result) {
    ApiSuccess(data: final coupons) => coupons,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});
