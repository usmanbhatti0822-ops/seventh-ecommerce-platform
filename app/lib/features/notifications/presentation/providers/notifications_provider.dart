import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/notifications_repository.dart";
import "../../../../core/network/api_result.dart";

final notificationsRepositoryProvider = Provider((ref) => NotificationsRepository());

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(notificationsRepositoryProvider);
  final result = await repo.list();
  return switch (result) {
    ApiSuccess(data: final notifications) => notifications,
    ApiFailure(message: final msg) => throw Exception(msg),
  };
});

final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
        data: (list) => list.where((n) => n["read"] != true).length,
        orElse: () => 0,
      );
});
