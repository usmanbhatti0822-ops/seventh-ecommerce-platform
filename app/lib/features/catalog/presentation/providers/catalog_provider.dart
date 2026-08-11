import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/catalog_repository.dart";
import "../../domain/entities/product.dart";
import "../../../../core/network/api_result.dart";

final catalogRepositoryProvider = Provider((ref) => CatalogRepository());

/// Home/Category listing state — AsyncValue gives us loading/error/data
/// handling for free in the UI via .when().
final productsProvider = FutureProvider.family<List<Product>, String?>((ref, search) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final result = await repo.fetchProducts(search: search);
  return switch (result) {
    ApiSuccess(data: final products) => products,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});

final productDetailProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final result = await repo.fetchProduct(id);
  return switch (result) {
    ApiSuccess(data: final product) => product,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});
