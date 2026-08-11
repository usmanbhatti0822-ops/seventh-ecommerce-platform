import "package:flutter_riverpod/flutter_riverpod.dart";
import "../repositories/admin_repository.dart";
import "../../../../core/network/api_result.dart";

final adminRepositoryProvider = Provider((ref) => AdminRepository());

T _unwrap<T>(ApiResult<T> result) => switch (result) {
      ApiSuccess(data: final d) => d,
      ApiFailure(message: final msg) => throw Exception(msg),
    };

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).dashboard());
});

final adminCustomersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).customers());
});

final adminReportsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).reports());
});

final adminSuppliersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).suppliers());
});

final adminStaffProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).staff());
});

final adminInventoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).inventory());
});

final adminOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return _unwrap(await ref.watch(adminRepositoryProvider).orders());
});
