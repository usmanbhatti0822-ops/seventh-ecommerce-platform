import "package:dio/dio.dart";
import "../../../../core/network/api_client.dart";
import "../../../../core/network/api_result.dart";

class NotificationsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResult<List<Map<String, dynamic>>>> list() async {
    try {
      final res = await _dio.get("/notifications");
      return ApiSuccess(List<Map<String, dynamic>>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not load notifications");
    }
  }

  Future<ApiResult<void>> markRead(String id) async {
    try {
      await _dio.patch("/notifications/$id/read");
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?["message"]?.toString() ?? "Could not update notification");
    }
  }
}
