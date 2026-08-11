import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/orders_repository.dart";
import "../../../../core/network/api_result.dart";

final ordersRepositoryProvider = Provider((ref) => OrdersRepository());

final myOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  final result = await repo.myOrders();
  return switch (result) {
    ApiSuccess(data: final orders) => orders,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});

final orderDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(ordersRepositoryProvider);
  final result = await repo.getOrder(id);
  return switch (result) {
    ApiSuccess(data: final order) => order,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});
