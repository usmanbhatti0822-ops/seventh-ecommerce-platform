import "package:dio/dio.dart";
import "../config/app_config.dart";
import "../storage/token_storage.dart";
import "mock_backend.dart";

/// Shared Dio-based API client used by both Customer app and Admin panel.
///
/// In demo mode (default — see [AppConfig]) every request is short-circuited
/// to the in-memory [MockBackend] instead of hitting the network, so the app
/// runs fully standalone. Repositories are written against the same Dio
/// interface either way, so nothing else in the app needs to know which mode
/// is active.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (AppConfig.demoMode) {
            try {
              final response = await MockBackend.instance.handle(options);
              handler.resolve(response);
            } on MockApiException catch (e) {
              handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: e.statusCode,
                  data: {"message": e.message},
                ),
              ));
            }
            return;
          }
          final token = await TokenStorage.read();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Real-mode 401 handling: clear the stale token so the next screen
          // navigation naturally routes back to Login instead of retrying
          // with a dead token.
          if (!AppConfig.demoMode && error.response?.statusCode == 401) {
            TokenStorage.clear();
          }
          handler.next(error);
        },
      ),
    );
}
