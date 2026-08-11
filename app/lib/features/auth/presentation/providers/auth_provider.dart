import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../data/repositories/auth_repository.dart";
import "../../../../core/storage/token_storage.dart";

final authRepositoryProvider = Provider((ref) => AuthRepository());

/// Whether the user currently has a stored auth token (used to gate routes / show login).
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final token = await TokenStorage.read();
  return token != null && token.isNotEmpty;
});
